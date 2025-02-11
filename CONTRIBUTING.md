# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue, email, or any other method with the owners of this repository before making a change.

Please note we have a [code of conduct](CODE_OF_CONDUCT.md), please follow it in all your interactions with the project.

## Development environment setup
1. Git clone the projects repository *(`git clone https://github.com/DiscordLuau/discord-luau.git`)*
2. Install all dependencies *(`pesde install`)*
	i. in the event pesde errors, try running pesde a second time.
3. Use `Lune` to start the `development.luau` script
	i. `lune run development`

## Code Style Guide
We've generally adopted a mix of Lunes lua styleguide, as well as Pesdes lua styleguides, these styleguides aren't written down anywhere in detail, but generally lean towards how one of the two projects write their code. *(Lean towards Lune, and where thats not possible - pesde.)*


## Issues and feature requests

You've found a bug in the source code, a mistake in the documentation or maybe you'd like a new feature? You can help us by [submitting an issue on GitHub](https://github.com/DiscordLuau/discord-luau/issues). Before you create an issue, make sure to search the issue archive -- your issue may have already been addressed!

Please try to create bug reports that are:

- _Reproducible._ Include steps to reproduce the problem.
- _Specific._ Include as much detail as possible: which version, what environment, etc.
- _Unique._ Do not duplicate existing opened issues.
- _Scoped to a Single Bug._ One bug per report.

**Even better: Submit a pull request with a fix or new feature!**

### How to submit a Pull Request

1. Search our repository for open or closed
   [Pull Requests](https://github.com/DiscordLuau/discord-luau/pulls)
   that relate to your submission. You don't want to duplicate effort.
2. Fork the project
3. Create your feature branch (`git checkout -b feat/amazing_feature`)
4. Commit your changes (`git commit -m 'feat: add amazing_feature'`)
	i. Discord-Luau uses [conventional commits](https://www.conventionalcommits.org), so please follow the specification in your commit messages.
5. Push to the branch (`git push origin feat/amazing_feature`)
6. [Open a Pull Request](https://github.com/DiscordLuau/discord-luau/compare?expand=1)
