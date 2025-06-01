# Git Branching Workflow for BYU-I Rideshare App: Step-by-Step Instructions

## Introduction

This document provides a direct, step-by-step guide on how to implement and use a Git branching system for our team. Following these instructions will significantly improve collaboration, minimize merge conflicts, and help maintain a stable codebase.

## Why You MUST Use a Branching System

Using a proper branching system is essential for our team's success because it:

* **Eliminates Main Branch Conflicts:** Each team member works in their own isolated "feature branch." Resolve conflicts in your dedicated branch, not on the `main` development line.
* **Isolates Your Work:** Develop new features or fix bugs without incomplete work from others interfering with your progress.
* **Maintains a Stable `main` Branch:** Your `main` branch will always hold stable, production-ready code.
* **Facilitates Code Review:** Easily review changes before they are merged into the main codebase, improving overall code quality.
* **Simplifies Rollbacks:** If a feature introduces a bug, quickly revert just that feature's changes without affecting other completed work.

## Recommended Strategy: Feature Branch Workflow

For our team's size, the **Feature Branch Workflow** is the simplest and most effective strategy.

### Core Concepts:

* **`main` Branch:**
    * This is the primary branch.
    * It **MUST always** hold stable, deployable code.
    * **NEVER work directly on the `main` branch.** All development occurs on separate feature branches.
* **Feature Branches:**
    * These are temporary branches created for every new task, feature, or bug fix.
    * Branch them off `main`, perform your work, and then merge them back into `main`.

---

## Step-by-Step Instructions: Your Branching Workflow

Follow these instructions for each task you begin. Assume your main branch is named `main`.

### **Step 1: Get Ready for a New Task (Pull the Latest `main`)**

Before you begin any new coding for a task, ensure your local `main` branch is perfectly up-to-date with the remote repository. This prevents you from building on old code.

* **Action:** Switch to the `main` branch.
    ```bash
    git checkout main
    ```
* **Action:** Pull the very latest changes from the remote `main` branch.
    ```bash
    git pull origin main
    ```
    *(**DO THIS** at the beginning of each day, or before starting any new task, to ensure your local `main` is current.)*

### **Step 2: Create a New Feature Branch for Your Task**

Always create a new, dedicated branch specifically for the task you're about to work on. This isolates your work.

* **Action:** Choose a clear and descriptive name for your branch.
    * **Good Naming Conventions:** `feature/my-rides-screen`, `feature/driver-management`, `feature/search-filter`, `fix/auth-bug`, `task/driver-management`.
* **Action:** Use this command to **create** your new branch and **switch** your working directory to it immediately.
    ```bash
    git checkout -b feature/your-task-name-here
    ```

### **Step 3: Work on Your Task & Commit Frequently**

Now you are on your isolated feature branch. Make all your code changes, add new files, and modify existing ones here.

* **Action:** As you complete small, logical parts of your task (e.g., "added button UI," "implemented service function," "fixed a specific bug"), **commit your changes regularly**. Don't wait until the very end. Smaller commits are easier to review and debug.
* **Command:** Stage all your changes (new, modified, deleted files).
    ```bash
    git add .
    ```
* **Command:** Commit your staged changes with a clear, concise message describing what you did.
    ```bash
    git commit -m "feat: [Your Feature Name] Implemented X functionality"
    ```
    *(**Example Commit Messages:** "feat: My Rides screen base UI", "refactor: updated RideService to filter by driverUid")*

* **Action:** **Push your feature branch to the remote repository often** (e.g., at the end of the day, after significant progress, or before taking a break). This backs up your work and makes it visible for teammates (and review).
    ```bash
    git push origin feature/your-task-name-here
    ```
    *(**Note:** The first time you push a new branch, Git might tell you to use `--set-upstream origin feature/your-task-name-here`. Copy and paste that exact command.)*

### **Step 4: Prepare to Merge Your Work into `main`**

When your feature is complete, thoroughly tested in your branch, and ready to be integrated into the main codebase:

* **Action:** **Pull the very latest changes from `main` into your feature branch.** This is a **critical step** that helps you resolve any potential conflicts *within your isolated branch* before you try to merge into the stable `main`.
    ```bash
    git checkout feature/your-task-name-here # Make sure you are on your feature branch
    git pull origin main                      # Pull from remote main into your feature branch
    ```
    *If `git pull` reports any **merge conflicts here**, **IMMEDIATELY resolve them** within your `feature/your-task-name-here` branch. Once resolved, commit the resolution and then push your feature branch again.*

### **Step 5: Merge Your Changes into `main` (Recommended: Via Pull Request)**

Once your feature branch is stable, fully tested, and up-to-date with `main`, it's time to integrate it.

* **Option A (HIGHLY Recommended for Platforms like GitHub/GitLab/Bitbucket): Create a Pull Request (PR).**
    1.  **Action:** After pushing your updated feature branch (from Step 4) to the remote, go to your repository's page in your web browser (e.g., GitHub).
    2.  **Action:** Look for a prominent prompt like "Compare & pull request" or "New pull request" for your recently pushed branch. Click it.
    3.  **Action:** Fill out the PR form:
        * Provide a clear title and detailed description of your changes.
        * Link to any relevant task or issue.
        * Assign teammates for code review.
    4.  **Action:** Wait for your teammates to review your code. Address any comments or suggested changes.
    5.  **Action:** Once reviewed and approved (and any conflicts are resolved), merge the PR. This action updates the `main` branch on the remote.

* **Option B (Merging Locally - Use only if no PR process is available or for very small, simple merges):**
    1.  **Action:** Switch back to the `main` branch:
        ```bash
        git checkout main
        ```
    2.  **Action:** Pull the very latest changes from the remote `main` (to ensure you have everyone else's recent merges):
        ```bash
        git pull origin main
        ```
    3.  **Action:** Merge your feature branch into `main`:
        ```bash
        git merge feature/your-task-name-here
        ```
    4.  **Action:** **Resolve any merge conflicts that might arise during this merge operation.** (This is why PRs are often preferred, as conflicts are frequently handled earlier in the PR interface.)
    5.  **Action:** Push the updated `main` branch to the remote repository:
        ```bash
        git push origin main
        ```

### **Step 6: Delete Your Feature Branch (After Successful Merge)**

Once your feature branch is successfully merged into `main` (and pushed to the remote), it's good practice to delete it to keep your repository clean.

* **Action:** Delete your local feature branch:
    ```bash
    git branch -d feature/your-task-name-here
    ```
    *(**Note:** Use `git branch -D feature/your-task-name-here` instead of `-d` if Git complains about unmerged changes, but be careful as `-D` is a "force delete".)*
* **Action:** Delete your feature branch from the remote repository:
    ```bash
    git push origin --delete feature/your-task-name-here
    ```

---

## Team Strategy for This Week's Tasks with Branching:

Use this branching workflow for all tasks this week:

1.  **Assign Tasks:** Assign each of the four tasks to a specific team member or a pair.
2.  **Create Branches:** Each person/pair **must create their own feature branch** for their assigned task (e.g., `feature/my-rides-screen`, `feature/driver-management`, `feature/search-filter`, `feature/my-joined-rides-screen`).
3.  **Work and Push:** Work on your task, committing and pushing to your respective feature branches regularly.
4.  **Pull Request & Review:** When a task is complete and stable, create a Pull Request to merge your feature branch into `main`. Encourage team members to review each other's code.
5.  **Merge & Delete:** Once approved and merged, delete your feature branch.

This structured approach will make your collaborative development much more organized and efficient!
