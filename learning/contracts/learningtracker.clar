;; Learning Achievement Tracker - A system for tracking and rewarding educational progress

(define-constant education-admin tx-sender)

;; Define the achievement token
(define-fungible-token learning-credits)

;; Error codes
(define-constant err-not-authorized (err u400))
(define-constant err-credit-shortage (err u401))
(define-constant err-invalid-value (err u402))
(define-constant err-milestone-completed (err u403))
(define-constant err-system-paused (err u404))
(define-constant err-invalid-principal (err u405))
(define-constant err-amount-too-large (err u406))
(define-constant err-course-limit-reached (err u407))
(define-constant err-prerequisite-not-met (err u408))

;; Security constants
(define-constant max-mint-amount u1000000)
(define-constant max-courses-per-user u50)
(define-constant max-credit-value u500)

;; System state
(define-data-var system-paused bool false)
(define-data-var total-credit-supply uint u0)

;; Data structures
(define-map student-progress principal {completed-courses: uint, total-credits: uint, level: uint})
(define-map course-completions {student: principal, course-id: uint} bool)
(define-map learning-milestones uint {credits-required: uint, bonus-reward: uint, title: (string-ascii 100)})
(define-map course-catalog uint {credit-value: uint, difficulty: uint, category: (string-ascii 50), prerequisites: (list 5 uint)})
(define-map authorized-instructors principal bool)
(define-map course-enrollment {student: principal, course-id: uint} {enrolled-block: uint, completed: bool})

;; Initialize course catalog with prerequisites
(map-set course-catalog u1 {credit-value: u20, difficulty: u1, category: "Programming Basics", prerequisites: (list)})
(map-set course-catalog u2 {credit-value: u35, difficulty: u2, category: "Web Development", prerequisites: (list u1)})
(map-set course-catalog u3 {credit-value: u50, difficulty: u3, category: "Blockchain Technology", prerequisites: (list u1 u2)})
(map-set course-catalog u4 {credit-value: u40, difficulty: u2, category: "Database Design", prerequisites: (list u1)})
(map-set course-catalog u5 {credit-value: u60, difficulty: u4, category: "Advanced Algorithms", prerequisites: (list u1 u2)})

;; Initialize learning milestones with enhanced rewards
(map-set learning-milestones u1 {credits-required: u100, bonus-reward: u25, title: "Novice Learner"})
(map-set learning-milestones u2 {credits-required: u300, bonus-reward: u75, title: "Advanced Student"})
(map-set learning-milestones u3 {credits-required: u500, bonus-reward: u150, title: "Expert Scholar"})
(map-set learning-milestones u4 {credits-required: u800, bonus-reward: u250, title: "Master Educator"})

;; Initialize education admin as authorized instructor
(map-set authorized-instructors education-admin true)

;; Read-only functions
(define-read-only (get-credit-balance (student principal))
  (ft-get-balance learning-credits student))

(define-read-only (get-student-progress (student principal))
  (default-to {completed-courses: u0, total-credits: u0, level: u0} (map-get? student-progress student)))

(define-read-only (check-course-completion (student principal) (course-id uint))
  (default-to false (map-get? course-completions {student: student, course-id: course-id})))

(define-read-only (get-course-details (course-id uint))
  (map-get? course-catalog course-id))

(define-read-only (get-milestone-info (milestone-id uint))
  (map-get? learning-milestones milestone-id))

(define-read-only (is-system-paused)
  (var-get system-paused))

(define-read-only (get-total-credit-supply)
  (var-get total-credit-supply))

(define-read-only (is-authorized-instructor (user principal))
  (default-to false (map-get? authorized-instructors user)))

(define-read-only (get-enrollment-info (student principal) (course-id uint))
  (map-get? course-enrollment {student: student, course-id: course-id}))

;; Private helper functions
(define-private (is-valid-principal (user principal))
  (is-standard user))

(define-private (check-prerequisites (student principal) (course-id uint))
  (let ((course-info (unwrap! (get-course-details course-id) false))
        (prerequisites (get prerequisites course-info)))
    (fold check-single-prerequisite prerequisites true)))

(define-private (check-single-prerequisite (prerequisite uint) (acc bool))
  (and acc (check-course-completion tx-sender prerequisite)))

(define-private (is-valid-category (category (string-ascii 50)))
  (and (> (len category) u0) (<= (len category) u50)))

(define-private (validate-prerequisites (prerequisites (list 5 uint)))
  (fold validate-single-prerequisite prerequisites true))

(define-private (validate-single-prerequisite (prerequisite uint) (acc bool))
  (and acc (and (> prerequisite u0) (<= prerequisite u100))))

;; Admin functions
(define-public (pause-system)
  (begin
    (asserts! (is-eq tx-sender education-admin) err-not-authorized)
    (var-set system-paused true)
    (ok true)))

(define-public (unpause-system)
  (begin
    (asserts! (is-eq tx-sender education-admin) err-not-authorized)
    (var-set system-paused false)
    (ok true)))

(define-public (add-authorized-instructor (instructor principal))
  (begin
    (asserts! (is-eq tx-sender education-admin) err-not-authorized)
    (asserts! (is-valid-principal instructor) err-invalid-principal)
    (map-set authorized-instructors instructor true)
    (ok true)))

(define-public (add-course (course-id uint) (credit-value uint) (difficulty uint) (category (string-ascii 50)) (prerequisites (list 5 uint)))
  (begin
    (asserts! (is-eq tx-sender education-admin) err-not-authorized)
    (asserts! (not (var-get system-paused)) err-system-paused)
    (asserts! (and (> course-id u0) (<= course-id u100)) err-invalid-value)
    (asserts! (and (> credit-value u0) (<= credit-value max-credit-value)) err-invalid-value)
    (asserts! (and (> difficulty u0) (<= difficulty u5)) err-invalid-value)
    (asserts! (is-valid-category category) err-invalid-value)
    (asserts! (validate-prerequisites prerequisites) err-invalid-value)
    (asserts! (is-none (get-course-details course-id)) err-invalid-value)
    (map-set course-catalog course-id {credit-value: credit-value, difficulty: difficulty, category: category, prerequisites: prerequisites})
    (ok true)))

;; Public functions
(define-public (award-credits (amount uint) (student principal))
  (begin
    (asserts! (not (var-get system-paused)) err-system-paused)
    (asserts! (is-authorized-instructor tx-sender) err-not-authorized)
    (asserts! (> amount u0) err-invalid-value)
    (asserts! (<= amount max-mint-amount) err-amount-too-large)
    (asserts! (is-valid-principal student) err-invalid-principal)
    (var-set total-credit-supply (+ (var-get total-credit-supply) amount))
    (ft-mint? learning-credits amount student)))

(define-public (enroll-in-course (course-id uint))
  (let ((course-info (unwrap! (get-course-details course-id) err-invalid-value))
        (current-progress (get-student-progress tx-sender)))
    (begin
      (asserts! (not (var-get system-paused)) err-system-paused)
      (asserts! (< (get completed-courses current-progress) max-courses-per-user) err-course-limit-reached)
      (asserts! (not (check-course-completion tx-sender course-id)) err-milestone-completed)
      (asserts! (check-prerequisites tx-sender course-id) err-prerequisite-not-met)
      (map-set course-enrollment {student: tx-sender, course-id: course-id} 
        {enrolled-block: stacks-block-height, completed: false})
      (ok true))))

(define-public (complete-course (course-id uint))
  (let ((course-info (unwrap! (get-course-details course-id) err-invalid-value))
        (enrollment-info (unwrap! (get-enrollment-info tx-sender course-id) err-invalid-value))
        (completion-key {student: tx-sender, course-id: course-id})
        (current-progress (get-student-progress tx-sender))
        (credit-value (get credit-value course-info)))
    (begin
      (asserts! (not (var-get system-paused)) err-system-paused)
      (asserts! (not (get completed enrollment-info)) err-milestone-completed)
      (asserts! (not (check-course-completion tx-sender course-id)) err-milestone-completed)
      (asserts! (> (- stacks-block-height (get enrolled-block enrollment-info)) u1) err-invalid-value) ;; Must wait at least 1 block
      (map-set course-completions completion-key true)
      (map-set course-enrollment {student: tx-sender, course-id: course-id}
        (merge enrollment-info {completed: true}))
      (map-set student-progress tx-sender 
        {completed-courses: (+ (get completed-courses current-progress) u1),
         total-credits: (+ (get total-credits current-progress) credit-value),
         level: (get level current-progress)})
      (var-set total-credit-supply (+ (var-get total-credit-supply) credit-value))
      (ft-mint? learning-credits credit-value tx-sender))))

(define-public (claim-milestone-reward (milestone-id uint))
  (let ((milestone-info (unwrap! (get-milestone-info milestone-id) err-invalid-value))
        (student-info (get-student-progress tx-sender))
        (required-credits (get credits-required milestone-info))
        (bonus-amount (get bonus-reward milestone-info)))
    (begin
      (asserts! (not (var-get system-paused)) err-system-paused)
      (asserts! (>= (get total-credits student-info) required-credits) err-credit-shortage)
      (asserts! (< (get level student-info) milestone-id) err-milestone-completed)
      (asserts! (<= bonus-amount max-mint-amount) err-amount-too-large)
      (map-set student-progress tx-sender 
        (merge student-info {level: milestone-id}))
      (var-set total-credit-supply (+ (var-get total-credit-supply) bonus-amount))
      (ft-mint? learning-credits bonus-amount tx-sender))))

(define-public (spend-credits (amount uint) (recipient principal))
  (begin
    (asserts! (not (var-get system-paused)) err-system-paused)
    (asserts! (>= (ft-get-balance learning-credits tx-sender) amount) err-credit-shortage)
    (asserts! (> amount u0) err-invalid-value)
    (asserts! (is-valid-principal recipient) err-invalid-principal)
    (asserts! (not (is-eq tx-sender recipient)) err-invalid-value)
    (ft-transfer? learning-credits amount tx-sender recipient)))

(define-public (consume-credits (amount uint))
  (begin
    (asserts! (not (var-get system-paused)) err-system-paused)
    (asserts! (>= (ft-get-balance learning-credits tx-sender) amount) err-credit-shortage)
    (asserts! (> amount u0) err-invalid-value)
    (var-set total-credit-supply (- (var-get total-credit-supply) amount))
    (ft-burn? learning-credits amount tx-sender)))
