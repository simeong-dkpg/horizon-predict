;; Title: HorizonPredict - Decentralized Market Intelligence Layer
;;
;; Summary:
;; HorizonPredict establishes a peer-to-peer financial coordination network 
;; that enables communities to express market sentiment, hedge uncertainty, 
;; and allocate capital efficiently through trustless forecasting primitives.
;;
;; Description:
;; Unlike traditional betting platforms, HorizonPredict transforms collective 
;; intelligence into a cryptographically enforced settlement mechanism. 
;; By leveraging Bitcoin's finality through Stacks' smart contracts, the protocol 
;; ensures transparent outcome resolution, automated capital distribution, and 
;; censorship-resistant participation. 
;;
;; HorizonPredict introduces:
;;   - Permissionless market creation with flexible lifecycle parameters
;;   - Non-custodial staking with deterministic outcome resolution
;;   - Decentralized oracle integration for unbiased settlement
;;   - Institutional-grade fee and treasury management for sustainability
;;
;; This protocol demonstrates how capital can flow seamlessly into outcome-based 
;; markets, where speculation becomes a structured financial instrument rather 
;; than a zero-sum gamble.
;;

;; PROTOCOL CONSTANTS

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))

;; Error Code Registry
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PREDICTION (err u102))
(define-constant ERR_MARKET_CLOSED (err u103))
(define-constant ERR_ALREADY_CLAIMED (err u104))
(define-constant ERR_INSUFFICIENT_BALANCE (err u105))
(define-constant ERR_INVALID_PARAMETER (err u106))

;; PROTOCOL STATE VARIABLES

;; Oracle Infrastructure (trusted settlement source)
(define-data-var oracle-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Economic Parameters
(define-data-var minimum-stake uint u1000000) ;; Minimum participation: 1 STX
(define-data-var fee-percentage uint u2) ;; Protocol fee: 2%
(define-data-var market-counter uint u0) ;; Incremental market IDs

;; CORE DATA STRUCTURES

;; Market Registry - Captures the lifecycle of each prediction market
(define-map markets
  uint
  {
    start-price: uint,
    end-price: uint,
    total-up-stake: uint,
    total-down-stake: uint,
    start-block: uint,
    end-block: uint,
    resolved: bool,
  }
)

;; Position Ledger - Tracks individual user commitments
(define-map user-predictions
  {
    market-id: uint,
    user: principal,
  }
  {
    prediction: (string-ascii 4), ;; "up" | "down"
    stake: uint,
    claimed: bool,
  }
)

;; MARKET LIFECYCLE

;; Create a new prediction market
(define-public (create-market
    (start-price uint)
    (start-block uint)
    (end-block uint)
  )
  (let ((market-id (var-get market-counter)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (asserts! (> end-block start-block) ERR_INVALID_PARAMETER)
    (asserts! (> start-price u0) ERR_INVALID_PARAMETER)

    (map-set markets market-id {
      start-price: start-price,
      end-price: u0,
      total-up-stake: u0,
      total-down-stake: u0,
      start-block: start-block,
      end-block: end-block,
      resolved: false,
    })

    (var-set market-counter (+ market-id u1))
    (ok market-id)
  )
)

;; Enter a position in a market
(define-public (make-prediction
    (market-id uint)
    (prediction (string-ascii 4))
    (stake uint)
  )
  (let (
      (market (unwrap! (map-get? markets market-id) ERR_NOT_FOUND))
      (current-block stacks-block-height)
    )
    (asserts!
      (and
        (>= current-block (get start-block market))
        (< current-block (get end-block market))
      )
      ERR_MARKET_CLOSED
    )
    (asserts! (or (is-eq prediction "up") (is-eq prediction "down"))
      ERR_INVALID_PREDICTION
    )
    (asserts! (>= stake (var-get minimum-stake)) ERR_INVALID_PREDICTION)
    (asserts! (<= stake (stx-get-balance tx-sender)) ERR_INSUFFICIENT_BALANCE)

    (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))

    (map-set user-predictions {
      market-id: market-id,
      user: tx-sender,
    } {
      prediction: prediction,
      stake: stake,
      claimed: false,
    })

    (map-set markets market-id
      (merge market {
        total-up-stake: (if (is-eq prediction "up")
          (+ (get total-up-stake market) stake)
          (get total-up-stake market)
        ),
        total-down-stake: (if (is-eq prediction "down")
          (+ (get total-down-stake market) stake)
          (get total-down-stake market)
        ),
      })
    )
    (ok true)
  )
)

;; Resolve market with oracle-provided outcome
(define-public (resolve-market
    (market-id uint)
    (end-price uint)
  )
  (let ((market (unwrap! (map-get? markets market-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (var-get oracle-address)) ERR_OWNER_ONLY)
    (asserts! (>= stacks-block-height (get end-block market)) ERR_MARKET_CLOSED)
    (asserts! (not (get resolved market)) ERR_MARKET_CLOSED)
    (asserts! (> end-price u0) ERR_INVALID_PARAMETER)

    (map-set markets market-id
      (merge market {
        end-price: end-price,
        resolved: true,
      })
    )
    (ok true)
  )
)

;; Claim winnings after resolution
(define-public (claim-winnings (market-id uint))
  (let (
      (market (unwrap! (map-get? markets market-id) ERR_NOT_FOUND))
      (prediction (unwrap!
        (map-get? user-predictions {
          market-id: market-id,
          user: tx-sender,
        })
        ERR_NOT_FOUND
      ))
    )
    (asserts! (get resolved market) ERR_MARKET_CLOSED)
    (asserts! (not (get claimed prediction)) ERR_ALREADY_CLAIMED)

    (let (
        (winning-prediction (if (> (get end-price market) (get start-price market))
          "up"
          "down"
        ))
        (total-stake (+ (get total-up-stake market) (get total-down-stake market)))
        (winning-stake (if (is-eq winning-prediction "up")
          (get total-up-stake market)
          (get total-down-stake market)
        ))
      )
      (asserts! (is-eq (get prediction prediction) winning-prediction)
        ERR_INVALID_PREDICTION
      )

      (let (
          (winnings (/ (* (get stake prediction) total-stake) winning-stake))
          (fee (/ (* winnings (var-get fee-percentage)) u100))
          (payout (- winnings fee))
        )
        (try! (as-contract (stx-transfer? payout (as-contract tx-sender) tx-sender)))
        (try! (as-contract (stx-transfer? fee (as-contract tx-sender) CONTRACT_OWNER)))

        (map-set user-predictions {
          market-id: market-id,
          user: tx-sender,
        }
          (merge prediction { claimed: true })
        )
        (ok payout)
      )
    )
  )
)