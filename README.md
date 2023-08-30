# SwiftTypoDetector

An easy to install, easy to use, swift typo detector for your console.

## Installation

* Run the setup script: `./setup.sh`
  * _Note_: If you get a `permission denied error`: `chmod +x ./setup.sh`

The setup script will:
* Install Homebrew (if not already installed)
* Install aspell (dependency) (via brew)
* Install the Ruby gems (via bundle install)
  * Just `ffi` gem needed

## Usage

* Run `./find_typos.rb /path/to/your-project`
  * Replace `/path/to/your-project` with the real path of your project.
  * _Note_: If you get a `permission denied error`: `chmod +x ./find_typos.rb`

### Learning words

If you want to provide a set of custom words:

1. Create a file named `learned_words.txt` in the root of the project you want to find typos on.
2. Populate the `.txt` file with one learned word per line.

You could copy and paste the [one in this project](./learned_words.txt)

**Sorting the learned_words file**

If you want to sort the sections of the `learned_word` file:

* Run the sort script: `./sort_txt_sections.sh path/to/your-project/learned_words.txt`
  * Replace `/path/to/your-project/` with the real path of your project.
