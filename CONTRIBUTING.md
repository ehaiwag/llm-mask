# Contributing to llm-mask

Thank you for your interest in contributing to **llm-mask**.

This project aims to provide a simple and reliable way to mask sensitive
information before sending text to LLM systems.

Contributions are welcome, including bug fixes, improvements, and new features.

---

# Development Setup

Clone the repository:

```
git clone https://github.com/ehaiwag/llm-mask.git
cd llm-mask
```

Run the installer locally:

```
bash install.sh
```

Reload your shell:

```
source ~/.zshrc
```

Test the commands:

```
maskclip
unmaskclip
```

---

# Project Structure

```
llm-mask/
│
├── README.md
├── install.sh
│
├── bin/
│   └── llm_mask.py
│
├── shell/
│   └── llm-mask.sh
│
└── config/
    └── sensitive.example.txt
```

| Component | Purpose |
| --- | --- |
| install.sh | Installation script |
| llm_mask.py | Core masking engine |
| llm-mask.sh | CLI wrapper for `maskclip` and `unmaskclip` |
| sensitive.txt | User-maintained sensitive phrases |

---

# Contribution Guidelines

Please follow these guidelines when contributing:

- Keep the tool **lightweight**
- Avoid introducing heavy dependencies
- Maintain **macOS and Linux compatibility**
- Ensure masking remains **fully reversible**
- Preserve the **clipboard-based workflow**

---

# Suggested Areas for Improvement

Contributions are especially welcome in the following areas:

- improved secret detection
- pip-based installation (`pip install llm-mask`)
- better CLI options
- fuzzy token recovery (in case an LLM slightly modifies tokens)
- browser extension integration
- Raycast / Alfred integration

---

# Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push the branch to your fork
5. Open a pull request

Please provide a clear description of the change and its motivation.

---

# Reporting Issues

If you encounter a bug or unexpected behavior, please open a GitHub issue and include:

- operating system
- shell type (zsh / bash)
- steps to reproduce
- relevant logs or error messages

---

Thank you for helping improve **llm-mask**.
