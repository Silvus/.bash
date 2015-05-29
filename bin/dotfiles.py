#! /usr/bin/env python3

"""
Setup dotfiles
"""

import os
import sys
import time
import configparser
import fileinput
from urllib.request import Request, urlretrieve
from urllib.error import URLError, HTTPError
from subprocess import Popen, PIPE

"""
Prints (with colors)
"""

COLOR_RESET = '\033[0m'
COLOR_RED = '\033[31m'
COLOR_GREEN = '\033[32m'
COLOR_YELLOW = '\033[33m'
COLOR_BLUE = '\033[34m'

def print_header(message):
    print('\n' + COLOR_BLUE + '⦿ ' + COLOR_RESET + message)

def print_success(message):
    print(COLOR_GREEN + '    ✔ ' + COLOR_RESET + message)

def print_info(message):
    print(COLOR_BLUE + '    ➤ ' + COLOR_RESET + message)

def print_warning(message):
    print(COLOR_YELLOW + '    ⚠ ' + COLOR_RESET + message)

def print_error(message):
    print(COLOR_RED + '    ✖ ' + COLOR_RESET + message)

"""
Helpers
"""

def assure_path_exist(path):
    """
    Create parents folders
    """
    dir = os.path.dirname(os.path.expanduser(path))
    if not os.path.exists(dir):
        os.makedirs(dir)

def exec_command(command, show_errors=True):
    """
    Execute a system command
    """
    p = Popen(command, stdout=PIPE, stderr=PIPE)
    output, errors = p.communicate()

    if p.returncode != 0 and show_errors:
        print_error(errors.decode('UTF-8'))

    return p.returncode == 0

def is_installed(prog):
    p = Popen(['which', prog], stdout=PIPE, stderr=PIPE)
    command_path, errors = p.communicate()

    if p.returncode != 0:
        print_error(errors.decode('UTF-8'))

    return len(command_path) > 0

def X_is_running():
    return exec_command(["xset", "-q"], False)

"""
Scan "app" directory and create an equivalent symlink
in home for each file.
If X is running, scan also "appdesktop"
"""

def scan_arbo(rootSource, rootDestination):
    for dirName, subdirList, fileList in os.walk(rootSource):
        for fileName in fileList:
            # Get relative dir from dotfiles root
            relativeDir = os.path.relpath(dirName, rootSource)
            # Add file name and handle "." (with normpath)
            relativeFile = os.path.normpath(os.path.join(relativeDir, fileName))

            # Create absolutes paths
            source = os.path.join(rootSource, relativeFile)
            destination = os.path.join(rootDestination, relativeFile)

            if not symlink(source, destination):
                return False

    return True

def symlink(src, dest):
    """
    Make a symlink
    """
    # Remove existing symlink
    if os.path.lexists(dest):
            os.remove(dest)
    # Check if source exist
    if os.path.exists(src):
        # Create directories if necessary
        assure_path_exist(dest)
        # Make symlink
        os.symlink(src, dest)
        print_success('➜ ' + os.path.relpath(dest, os.path.expanduser('~')))
        return True
    else:
        print_error(src + " doesn't exist")
        return False

def symlink_root(src, dest):
    """
    Make a symlink with sudo (no update if it already exists)
    """
    # Check if source exist
    if os.path.exists(src):
        # Check if destination already exist
        if os.path.exists(dest):
            print_info('Symlink (sudo) exist: ' + os.path.basename(dest))
            return True
        # Create directories if necessary
        assure_path_exist(dest)
        # Make symlink
        print_success('➜ ' + dest)
        return exec_command(['sudo', 'ln', '-s', src, dest])
    else:
        print_error(src + " doesn't exist")
        return False

"""
Download file and set executable permission
Only if file is older than 7 days
"""

def report_download(count, blockSize, totalSize):
    """
    Report download status in percentage
    """
    percent = int(count*blockSize*100/totalSize)
    sys.stdout.write("\r%d%%" % percent + ' complete')
    sys.stdout.flush()

def download(url, destination):
    """
    Check url status and download file
    """
    # Create parents folders
    assure_path_exist(destination)

    if need_to_download(destination):
        req = Request(url)
        try:
            urlretrieve(url, destination, reporthook=report_download)
        except HTTPError as e:
            print_warning(url, 'unavailable.', 'Error code:', e.code)
        except URLError as e:
            print_warning(url, 'unavailable.', 'Reason:', e.reason)
        else:
            # everything is fine
            os.chmod(destination, 0o755)
            sys.stdout.flush()
            sys.stdout.write("\r" + COLOR_GREEN + "    ✔ " + COLOR_RESET + "Download complete: %s" % os.path.basename(destination) + '\n')
    else:
        print_info('Already present: ' + os.path.basename(destination))

def need_to_download(path):
    """
    Check if destination exist and is older than 7 days
    """
    if os.path.isfile(path):
        # File exist, check his age
        now = time.time()
        limit = 60*60*24*7  # Number of seconds in 7 days
        return os.stat(path).st_mtime < now - limit
    else:
        # File doesn't exist
        return True

"""
Generate config from multiple files
"""
def generate_config(outfilename, filenames):
    with open(outfilename, 'w') as fout:
        fout.write('# DO NOT EDIT THIS FILE BY HAND.\n# YOUR CHANGES WILL BE OVERWRITTEN !\n\n')
        for line in fileinput.input(filenames):
            fout.write(line)
    print_success('Generated: ' + outfilename)

"""
Clone or update repository
"""

def git_clone(url, destination):
    print_info('Clone ' + destination)
    return exec_command(['git', 'clone', url, destination])

def git_pull(destination):
    print_info('Update ' + destination)
    return exec_command(['git', '--work-tree=' + destination, '--git-dir=' + destination + '/.git', 'pull', 'origin', 'master'])

def git_version(destination):
    """
    Get current commit
    """
    p = Popen(['git', '--work-tree=' + destination, '--git-dir=' + destination + '/.git', 'rev-parse', 'HEAD'], stdout=PIPE, stderr=PIPE)
    version, errors = p.communicate()
    if p.returncode != 0:
        print_error(errors.decode('UTF-8'))
        return False
    else:
        return version

def clone_or_update(url, destination):
    if os.path.exists(destination):
        git_pull(destination)
    else:
        git_clone(url, destination)

def clone_or_update_dotfiles():
    """
    Clone or update dotfiles
    """
    dotfiles_path = os.path.expanduser('~/.dotfiles')

    if len(sys.argv) > 1 and sys.argv[1] == 'restarted':
        print_header('Dotfiles updated')
    else:
        print_header('Dotfiles')

    if not os.path.exists(dotfiles_path):
        # dotfiles directory doesn't exist? Clone it
        git_clone('https://github.com/Silvus/dotfiles.git', os.path.expanduser('~/.dotfiles'))

    # Without argument or argument is "restarted"
    elif len(sys.argv) == 1 or (len(sys.argv) > 1 and sys.argv[1] != 'restarted'):
        # Get current commit
        dot_version_prev = git_version(dotfiles_path)

        # Update
        git_pull(dotfiles_path)

        # Get current commit
        dot_version_next = git_version(dotfiles_path)

        if dot_version_prev != dot_version_next:
            # Restart current script if version change
            os.execl(sys.executable, sys.executable, sys.argv[0], 'restarted', * sys.argv[2:])

"""
Main
"""

def read_config(config_file):
    # Check for config file
    if os.path.isfile(config_file):
        # Read conf
        config = configparser.ConfigParser()
        config.read(config_file)
        # Assure each directory in "directories" section exist
        if config.has_section('directories'):
            for _, path_list in config.items('directories'):
                for path in path_list.split('\n'):
                    assure_path_exist(path)
        # Download each item in "download" section
        if config.has_section('download'):
            for destination, url in config.items('download'):
                download(url, os.path.expanduser(destination))
        # Clone each item in "clone" section
        if config.has_section('clone'):
            for destination, url in config.items('clone'):
                clone_or_update(url, os.path.expanduser(destination))
    else:
        # Config not found
        print_error("Config file " + config_file + " doesn't exist")
        sys.exit(1)

def check_requirements():
    if not is_installed('git'):
        print_error('Git is missing. Aborting.')
        sys.exit(1)


if __name__ == '__main__':

    # Requirements
    check_requirements()

    # Self update
    clone_or_update_dotfiles()

    # Config file
    config_file = os.path.expanduser('~/.dotfiles/dotconf')

    # Make symlinks
    rootSource = os.path.expanduser('~/.dotfiles/app')
    rootDesktopSource = os.path.expanduser('~/.dotfiles/appdesktop')
    rootDestination = os.path.expanduser('~')
    print_header('Symlinks apps')
    if scan_arbo(rootSource, rootDestination):
        if X_is_running():
            print_header('Symlinks desktop apps')
            scan_arbo(rootDesktopSource, rootDestination)

    # Dowload Apps
    print_header('Download apps')
    read_config(config_file)

    # TODO : Specials cases
    # --------------

    # Bash Completions
    print_header('Bash')
    symlink_root(os.path.expanduser('~/.dotfiles/bash/completion/tmux'), '/etc/bash_completion.d/tmux')
    symlink_root(os.path.expanduser('~/.dotfiles/bash/completion/dev'), '/etc/bash_completion.d/dev')
    symlink_root(os.path.expanduser('~/.dotfiles/bash/completion/go'), '/etc/bash_completion.d/go')
    symlink_root(os.path.expanduser('~/.dotfiles/bash/completion/sshrc'), '/etc/bash_completion.d/sshrc')
    symlink_root(os.path.expanduser('~/.dotfiles/bash/completion/composer'), '/etc/bash_completion.d/composer')

    # Generated sshrc config
    print_header('Sshrc')
    generate_config(os.path.expanduser("~/.sshrc"), [
        os.path.expanduser("~/.dotfiles/sshrc/sshrc_main"),
        os.path.expanduser("~/.dotfiles/bash/aliases/01_main.bash"),
        os.path.expanduser("~/.dotfiles/bash/aliases/04_prompt.bash"),
        os.path.expanduser("~/.dotfiles/sshrc/sshrc_ascii"),
    ])

    sys.exit(0)
