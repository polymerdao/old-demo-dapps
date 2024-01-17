# Demo dApps for Polymer

Welcome to the official repository for [Polymer](https://polymerlabs.org) demo applications! This repository serves as a centralized hub for both official (maintained by the Polymer Labs team and used in the official docs) and community-contributed demo apps, showcasing the capabilities and use cases of Polymer x [IBC](https://ibcprotocol.dev) interoperability.

## Repository Structure

This repository is divided into two main directories:

- **`/polymer-labs-official`**: Contains demo applications maintained by the official maintainers of Polymer. These demos are used in the official documentation and are regularly updated.

- **`/community`**: A vibrant space for community members to contribute their own demo apps. There are two ways to contribute: by adding code directly to this repository or by linking to your own repository.

## Contributing to the Community Directory

We welcome and encourage contributions from our community! Here’s how you can contribute:

### Option 1: Direct Contribution

1. **Fork the Repository:** Start by forking this repository.
2. **Add Your Demo App:** Place your demo app in the `/community` directory (separate directory for your project).
3. **Create a Pull Request:** Once you've added your demo, create a pull request to the main repository with a detailed description of your app.

### Option 2: External Repository Reference

If you prefer to maintain your demo in your own repository, you can add a reference to it in the **`explore-apps.md`** file you'll find in the `/community`. This contains curated list of community projects. It includes references to projects maintained in the `/community` directory and links to external repositories.

### Option 3: Adding as a Git Submodule

To add your repository as a git submodule:

1. **Clone the Main Repository:** If you haven't already, clone this repository:
   ```
   git clone [Main Repository URL]
   ```
2. **Add Your Repository as a Submodule:**
   ```
   git submodule add [Your Repository URL] community/[Your Project Name]
   ```
3. **Commit and Push the Changes:**
   ```
   git commit -m "Added [Your Project Name] as a submodule"
   git push
   ```
4. **Create a Pull Request:** Submit a pull request with your changes.

## Contribution Guidelines

Before contributing, please read our [Contribution Guidelines](LINK_TO_GUIDELINES). This includes coding standards, documentation expectations, and more.

## Acknowledgments

Contributors are the heartbeat of this project! We maintain a [Contributors List](LINK_TO_CONTRIBUTORS_FILE) to acknowledge the hard work and dedication of everyone who contributes.

## Questions or Suggestions?

Feel free to open an issue for questions, suggestions, or discussions related to this repository. For further discussion as well as a showcase of some community projects, check out the [Polymer developer forum](https://forum.polymerlabs.org).

Thank you for being a part of our community!

