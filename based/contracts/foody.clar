;; Farmer Registration & Verification System
;; A decentralized system for registering farmers and verifying their information

;; Define data variables
(define-data-var admin principal tx-sender)
(define-map verifiers principal bool)
(define-map farmers 
  principal 
  {
    name: (string-utf8 100),
    location: (string-utf8 100),
    produce-type: (string-utf8 100),
    verified: bool,
    verified-by: (optional principal)
  }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-REGISTERED u101)
(define-constant ERR-NOT-REGISTERED u102)
(define-constant ERR-NOT-VERIFIER u103)

;; Admin functions
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
    (ok (map-set verifiers verifier true))
  )
)

(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
    (ok (map-set verifiers verifier false))
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
    (ok (var-set admin new-admin))
  )
)

;; Farmer registration functions
(define-public (register-farmer (name (string-utf8 100)) (location (string-utf8 100)) (produce-type (string-utf8 100)))
  (begin
    (asserts! (is-none (map-get? farmers tx-sender)) (err ERR-ALREADY-REGISTERED))
    (ok (map-set farmers tx-sender {
      name: name,
      location: location,
      produce-type: produce-type,
      verified: false,
      verified-by: none
    }))
  )
)

(define-public (update-farmer-info (name (string-utf8 100)) (location (string-utf8 100)) (produce-type (string-utf8 100)))
  (let ((farmer-data (unwrap! (map-get? farmers tx-sender) (err ERR-NOT-REGISTERED))))
    (ok (map-set farmers tx-sender (merge farmer-data {
      name: name,
      location: location,
      produce-type: produce-type
    })))
  )
)

;; Verification functions
(define-public (verify-farmer (farmer principal))
  (let ((farmer-data (unwrap! (map-get? farmers farmer) (err ERR-NOT-REGISTERED))))
    (asserts! (default-to false (map-get? verifiers tx-sender)) (err ERR-NOT-VERIFIER))
    (ok (map-set farmers farmer (merge farmer-data {
      verified: true,
      verified-by: (some tx-sender)
    })))
  )
)

(define-public (revoke-verification (farmer principal))
  (let ((farmer-data (unwrap! (map-get? farmers farmer) (err ERR-NOT-REGISTERED))))
    (asserts! (or 
      (is-eq tx-sender (var-get admin))
      (is-eq (some tx-sender) (get verified-by farmer-data))
    ) (err ERR-NOT-AUTHORIZED))
    (ok (map-set farmers farmer (merge farmer-data {
      verified: false,
      verified-by: none
    })))
  )
)

;; Read-only functions
(define-read-only (get-farmer-info (farmer principal))
  (map-get? farmers farmer)
)

(define-read-only (is-verified (farmer principal))
  (match (map-get? farmers farmer)
    farmer-data (get verified farmer-data)
    false
  )
)

(define-read-only (is-verifier (address principal))
  (default-to false (map-get? verifiers address))
)