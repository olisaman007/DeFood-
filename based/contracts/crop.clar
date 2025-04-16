;; crop-registry.clar
;; Registry for tracking crop supply chain information

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u101))
(define-constant err-not-found (err u102))

;; Define the crop token contract principal
;; Replace with your actual contract address when deployed
(define-constant crop-token-principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.crop-token)

;; Data maps for supply chain tracking
(define-map supply-chain-events
  { token-id: uint, event-id: uint }
  {
    timestamp: uint,
    event-type: (string-ascii 64),
    location: (string-ascii 128),
    handler: principal,
    details: (string-ascii 64)
  }
)

(define-map token-event-count
  uint
  uint
)

;; Check if a principal is authorized to handle a specific token
(define-map authorized-handlers
  { token-id: uint, handler: principal }
  bool
)

;; Read-only functions
(define-read-only (get-supply-chain-event (token-id uint) (event-id uint))
  (match (map-get? supply-chain-events { token-id: token-id, event-id: event-id })
    event (ok event)
    (err err-not-found)
  )
)

(define-read-only (get-event-count (token-id uint))
  (default-to u0 (map-get? token-event-count token-id))
)

(define-read-only (is-authorized-handler (token-id uint) (handler principal))
  (default-to false (map-get? authorized-handlers { token-id: token-id, handler: handler }))
)

;; Add a new supply chain event
(define-public (add-supply-chain-event
    (token-id uint)
    (event-type (string-ascii 64))
    (location (string-ascii 128))
    (details (string-ascii 64)))
  (let
    (
      (current-count (get-event-count token-id))
      (new-count (+ current-count u1))
      (event {
        timestamp: stacks-block-height,
        event-type: event-type,
        location: location,
        handler: tx-sender,
        details: details
      })
    )
    ;; Add the event and update the count
    (map-set supply-chain-events { token-id: token-id, event-id: new-count } event)
    (map-set token-event-count token-id new-count)
    (ok new-count)
  )
)

;; Authorize a handler
(define-public (authorize-handler (token-id uint) (handler principal))
  (begin
    ;; Check if caller is the token owner (simplified for now)
    (map-set authorized-handlers { token-id: token-id, handler: handler } true)
    (ok true)
  )
)

;; Revoke handler authorization
(define-public (revoke-handler (token-id uint) (handler principal))
  (begin
    ;; Check if caller is the token owner (simplified for now)
    (map-set authorized-handlers { token-id: token-id, handler: handler } false)
    (ok true)
  )
)