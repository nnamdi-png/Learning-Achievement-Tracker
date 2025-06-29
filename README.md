
# 🎓 Learning Achievement Tracker

The **Learning Achievement Tracker** is a Clarity smart contract designed to gamify education by tracking students' progress, awarding fungible learning credits, and providing milestone-based rewards. It serves as a decentralized education rewards system for students and administrators.

##  Features

* **Fungible Token Support**: Introduces `learning-credits` token for rewarding completed courses and milestones.
* **Student Progress Tracking**: Records completed courses, total credits earned, and milestone level.
* **Course Catalog**: Maintains a list of courses with their credit values, difficulty, and category.
* **Milestone Rewards**: Grants bonus credits when students hit learning thresholds.
* **Spending & Burning**: Allows users to transfer or consume their earned credits.

##  Data Structures

* `student-progress`: Tracks courses completed, credits earned, and current level.
* `course-completions`: Maps student-course pairs to a completion status.
* `learning-milestones`: Defines required credits, rewards, and titles for each milestone.
* `course-catalog`: Stores course metadata including credit value, difficulty, and category.

##  Public Functions

* `award-credits`: Admin-only function to manually award credits to a student.
* `complete-course`: Awards credits automatically when a course is completed.
* `claim-milestone-reward`: Rewards students upon reaching credit-based milestones.
* `spend-credits`: Transfers tokens to another user.
* `consume-credits`: Burns tokens to represent usage.

##  Read-Only Functions

* `get-credit-balance`: Returns a student's learning credit balance.
* `get-student-progress`: Returns progress stats for a student.
* `check-course-completion`: Verifies if a student has completed a specific course.
* `get-course-details`: Fetches metadata about a course.
* `get-milestone-info`: Retrieves milestone reward and requirement details.

## Authorization

Only the `education-admin` (contract deployer) can:

* Call `award-credits`

##  Error Codes

| Error Constant            | Code | Meaning                               |
| ------------------------- | ---- | ------------------------------------- |
| `err-not-authorized`      | 400  | Only admin can perform this action    |
| `err-credit-shortage`     | 401  | Insufficient credits                  |
| `err-invalid-value`       | 402  | Input value is invalid                |
| `err-milestone-completed` | 403  | Already completed milestone or course |

## Example Courses

* **Programming Basics**: 20 credits
* **Web Development**: 35 credits
* **Blockchain Technology**: 50 credits

## Milestones

* **Novice Learner**: 100 credits → +25 bonus
* **Advanced Student**: 300 credits → +75 bonus
* **Expert Scholar**: 500 credits → +150 bonus
