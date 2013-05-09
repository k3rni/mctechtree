## Using MCTechTree from inside Computercraft

1. Get the code from https://gist.github.com/k3rni/5400291
2. Upload, paste or type it into the Computercraft editor
3. Alternatively, install [cc-get](http://cc-get.djranger.com/) and then run `cc-get mctechtree`
4. Run it: `mctechtree <item name>`

## Contributing

1. Clone the repository
2. Ensure you are working from the latest HEAD
3. Create a new branch for your changes, name it appropriately (e.g. the mod you're adding recipes for, a feature name)
3. Write recipes and/or code.
4. Submit a pull request.


## Checking your work

Run `techtree.rb` after each set of changes in the recipe files. It will tell you what's wrong - missing items, naming conflicts, bad definitions. Check your YAML files with a validator (such as http://yamllint.com) if you're not sure, as these errors tend to give rather cryptic messages.

