;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname Fury_Breakout_2020) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))

;;; Libraries

; a library for drawing images
(require 2htdp/image)
; a library for making an interactive program
(require 2htdp/universe)
; a library for creating sounds
(require rsound)

;;; Constants

; seconds per clock tick
(define SPT 1)
; whether to debug or not
(define DEBUG? #false)

; background color
(define BG-COLOR "black")

; character block length in pixels
(define CHAR-BLK-LENGTH 24)

; number of columns in playfield
(define PF-COL-COUNT 28)
; number of rows in playfield
(define PF-ROW-COUNT 32)

; playfield spacing in pixels
(define PF-SPACING (/ CHAR-BLK-LENGTH 4))

; ball radius in pixels
(define BALL-RADIUS (/ PF-SPACING 2))

; brick width in pixels
(define BRICK-WIDTH (* CHAR-BLK-LENGTH 2))
; brick height in pixels
(define BRICK-HEIGHT CHAR-BLK-LENGTH)
; illuminated brick width in pixels
(define IBRICK-WIDTH (- BRICK-WIDTH PF-SPACING))
; illuminated brick height in pixels
(define IBRICK-HEIGHT (- BRICK-HEIGHT PF-SPACING))

; wall thickness in pixels
(define WALL-THICKNESS IBRICK-HEIGHT)

; playfield width in pixels
(define PF-WIDTH (* CHAR-BLK-LENGTH PF-COL-COUNT))
; playfield height in pixels
(define PF-HEIGHT (* CHAR-BLK-LENGTH PF-ROW-COUNT))

; playfield image
(define PF-IMG (rectangle PF-WIDTH PF-HEIGHT "solid" BG-COLOR))

; backwall length
(define BACKWALL-LENGTH (- PF-WIDTH PF-SPACING))
; backwall image
(define BACKWALL-IMG (rectangle BACKWALL-LENGTH WALL-THICKNESS "solid" "blue"))
; sidewall image
(define SIDEWALL-IMG
  (above (rectangle WALL-THICKNESS (+ (/ PF-SPACING 2)
                                      (* 4 BRICK-HEIGHT)) "solid" "blue")
         (rectangle WALL-THICKNESS (* 4 BRICK-HEIGHT) "solid" "orange")
         (rectangle WALL-THICKNESS (* 4 BRICK-HEIGHT) "solid" "green")
         (rectangle WALL-THICKNESS (* 16 BRICK-HEIGHT) "solid" "yellow")
         (rectangle WALL-THICKNESS BRICK-HEIGHT "solid" "blue")
         (rectangle WALL-THICKNESS (- (* 2 BRICK-HEIGHT)
                                      (/ PF-SPACING 2)) "solid" "white")))

; background image
(define BG-IMG
  (overlay (above BACKWALL-IMG
                  (beside SIDEWALL-IMG
                          (rectangle (- BACKWALL-LENGTH (* 2 WALL-THICKNESS))
                                     (image-height SIDEWALL-IMG)
                                     "solid" "transparent")
                          SIDEWALL-IMG))
           PF-IMG))

;;; Data types

; a NonnegativeNumber is a Number greater than or equal to zero
; interpretation: a non-negative number

; a NonnegativeInteger is one of the following:
; - 0                         ; zero
; - (add1 NonnegativeInteger) : a positive Integer
; interpretation: a non-negative integer

; a Ball is (make-ball x y speed dir lastbrick paddle-hit-count)
; interpretation: a ball with position 's' and velocity 'v'
(define-struct ball [x y speed dir lastbrick paddle-hit-count])

; a Block is (make-block NonnegativeInteger NonnegativeInteger)
; interpretation: a block in row number 'row' and column number 'col'
(define-struct brick [col row])

; a Paddle is (make-paddle Number Number NonnegativeNumber)
; interpretation: a paddle with horizontal position 'sx',
;                 horizontal velocity 'vx', and
;                 width 'w' in pixels
(define-struct paddle [x row speed dir width])

; a Breakout is (make-breakout Ball List<Block>)
(define-struct breakout [loba lobr lop])

; others
(define-struct collision-geometry [left top right bottom])
(define-struct other [row])

;; Helpers

(define (row->color row)
  (cond
    [(<= 0 row 4) "blue"]
    [(<= 5 row 8) "orange"]
    [(<= 9 row 12) "green"]
    [(<= 13 row 28) "yellow"]
    [(<= 29 row 29) "blue"]
    [(<= 30 row 31) "white"]))

(define (row->y row)
  (* row CHAR-BLK-LENGTH))

(define (col->x col)
  (* col CHAR-BLK-LENGTH))

(define (brick-collision-geometry a-brick)
  (local ((define x (col->x (brick-col a-brick)))
          (define y (row->y (brick-row a-brick)))
          (define a-top (- y (/ IBRICK-HEIGHT 2))))
    (make-collision-geometry x a-top
                             (+ x BRICK-WIDTH)
                             (+ a-top BRICK-HEIGHT))))

(define (paddle-collision-geometry a-paddle)
  (local ((define x (paddle-x a-paddle))
          (define y (row->y (paddle-row a-paddle)))
          (define a-top (- y (/ (+ IBRICK-HEIGHT PF-SPACING) 2))))
    (make-collision-geometry x a-top
                             (+ x (paddle-width a-paddle))
                             (+ y IBRICK-HEIGHT))))

(define LEFT
  (+ WALL-THICKNESS (/ PF-SPACING 2)))

(define RIGHT
  (- PF-WIDTH LEFT))

(define TOP
  (- BRICK-HEIGHT (/ IBRICK-HEIGHT 2)))

(define BOTTOM
  (- PF-HEIGHT CHAR-BLK-LENGTH))

;;; Data examples

; List<Paddle>
(define LOP-0 (build-list (/ (- PF-COL-COUNT 2) 2)
                          (lambda (n)
                            (make-paddle (col->x (+ (* 2 n) 1)) 29 0 0 BRICK-WIDTH))))

; List<Block>
(define LOBR-0 (append (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 1)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 2)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 3)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 4)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 9)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 10)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 11)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 12)))))

; Ball
(define LOBA-0 (list (make-ball (* PF-WIDTH 1/6) (row->y 22) 15 (/ pi 4) (make-other 0) 0)
                     (make-ball (* PF-WIDTH 2/6) (row->y 22) 15 (/ pi 4) (make-other 0) 0)
                     (make-ball (* PF-WIDTH 3/6) (row->y 22) 15 (/ pi 4) (make-other 0) 0)
                     (make-ball (* PF-WIDTH 4/6) (row->y 22) 15 (/ pi 4) (make-other 0) 0)
                     (make-ball (* PF-WIDTH 5/6) (row->y 22) 15 (/ pi 4) (make-other 0) 0)))

; Breakout
(define BREAKOUT0 (make-breakout LOBA-0 LOBR-0 LOP-0))

;; Functions

(define (ball-vx a-ball)
  (* (cos (ball-dir a-ball))
     (ball-speed a-ball)
     ;SPT
     ))

(define (ball-vy a-ball)
  (* (sin (ball-dir a-ball))
     (ball-speed a-ball)
     ;SPT
     ))

(define (reverseXDir dir)
  (* (sgn dir) (- pi (abs dir))))

(define (reverseYDir dir)
  (- dir))

(define (get-first p? l)
  (cond
    [(empty? l) #false]
    [else
     (local ((define first-l (first l)))
       (if (p? first-l)
           first-l
           (get-first p? (rest l))))]))

(define (get-dir x a-paddle)
  (local ((define a-collision-geometry (paddle-collision-geometry a-paddle))
          (define left (collision-geometry-left a-collision-geometry))
          (define right (collision-geometry-right a-collision-geometry))
          (define width (- right left)))
    (cond
      [(and (<= (+ left (* width 0/4)) x) (< x (+ left (* width 1/4))))
       (* pi -3/4)]
      [(and (<= (+ left (* width 1/4)) x) (<= x (+ left (* width 2/4))))
       (* pi -2/3)]
      [(and (< (+ left (* width 2/4)) x) (<= x (+ left (* width 3/4))))
       (* pi -1/3)]
      [(and (< (+ left (* width 3/4)) x) (<= x (+ left (* width 4/4))))
       (* pi -1/4)])))

; update : Breakout -> Breakout
; update 'a-brkt' for one clock tick
(define (update-ball a-ball a-brkt)
  (local (; current Blocks in 'a-brkt'
          (define a-lobr (breakout-lobr a-brkt))
          ; current Paddle in 'a-brkt'
          (define a-lop (breakout-lop a-brkt))
          ; initial position
          (define x1 (ball-x a-ball))
          (define y1 (ball-y a-ball))
          ; final position without collisions
          (define x2 (+ x1 (ball-vx a-ball)))
          (define y2 (+ y1 (ball-vy a-ball)))
          (define new-ball
            (cond
              ; right sidewall collision
              [(>= (+ x2 BALL-RADIUS) RIGHT)
               (make-ball (- RIGHT BALL-RADIUS)
                          y2
                          (ball-speed a-ball)
                          (reverseXDir (ball-dir a-ball))
                          (ball-lastbrick a-ball)
                          0)]
              ; left sidewall collision
              [(<= (- x2 BALL-RADIUS) LEFT)
               (make-ball (+ LEFT BALL-RADIUS)
                          y2
                          (ball-speed a-ball)
                          (reverseXDir (ball-dir a-ball))
                          (ball-lastbrick a-ball)
                          0)]
              ; no collision
              [else
               (make-ball x2 y2
                          (ball-speed a-ball)
                          (ball-dir a-ball)
                          (ball-lastbrick a-ball)
                          0)]))
          (define x3 (ball-x new-ball))
          (define y3 (ball-y new-ball))
          (define (brick-collision? a-brick)
            (local ((define a-collision-geometry (brick-collision-geometry a-brick))
                    (define left (collision-geometry-left a-collision-geometry))
                    (define top (collision-geometry-top a-collision-geometry))
                    (define right (collision-geometry-right a-collision-geometry))
                    (define bottom (collision-geometry-bottom a-collision-geometry)))
              (and (<= left x3 right)
                   (<= top y3 bottom)
                   (or (and (other? (ball-lastbrick new-ball))
                            (< 1 (abs (- (other-row (ball-lastbrick new-ball))
                                         (brick-row a-brick)))))
                       (and (brick? (ball-lastbrick new-ball))
                            (< 3 (abs (- (brick-row (ball-lastbrick new-ball))
                                         (brick-row a-brick)))))))))
          (define (paddle-collision? a-paddle)
            (local ((define a-collision-geometry (paddle-collision-geometry a-paddle))
                    (define left (collision-geometry-left a-collision-geometry))
                    (define top (collision-geometry-top a-collision-geometry))
                    (define right (collision-geometry-right a-collision-geometry))
                    (define bottom (collision-geometry-bottom a-collision-geometry)))
              (and (<= left x3 right)
                   (<= top y3 bottom))))
          (define collided-brick (get-first brick-collision? a-lobr))
          (define collided-paddle (get-first paddle-collision? a-lop)))
    (cond
      ; bottom of playfield collision
      [(> (+ y3 BALL-RADIUS) BOTTOM)
       (make-ball x3 y3
                  (ball-speed new-ball)
                  (reverseYDir (ball-dir new-ball))
                  (ball-lastbrick new-ball)
                  0)]
      ; backwall collision
      [(< y3 TOP)
       (make-ball x3 y3
                  (ball-speed new-ball)
                  (reverseYDir (ball-dir new-ball))
                  (make-other 0)
                  0)]
      ; brick collision
      [(not (false? collided-brick))
       (make-ball x3 y3
                  (ball-speed new-ball)
                  (reverseYDir (ball-dir new-ball))
                  collided-brick
                  0)]
      ; paddle collision
      [(not (false? collided-paddle))
       (make-ball x3 y3
                  (ball-speed new-ball)
                  (get-dir x3 collided-paddle)
                  (make-other (paddle-row collided-paddle))
                  0)]
      ; no collision
      [else
       (make-ball x3 y3
                  (ball-speed new-ball)
                  (ball-dir new-ball)
                  (ball-lastbrick new-ball)
                  0)])))

(define (remove-bricks a-loba a-lobr)
  (cond
    [(empty? a-loba) a-lobr]
    [else
     (remove (ball-lastbrick (first a-loba))
             (remove-bricks (rest a-loba) a-lobr))]))

(define (update a-brkt)
  (local ((define a-lobr (breakout-lobr a-brkt))
          (define a-loba (breakout-loba a-brkt))
          (define new-loba
            (map (lambda (a-ball)
                   (update-ball a-ball a-brkt))
                 a-loba)))
    (make-breakout new-loba
                   (remove-bricks new-loba a-lobr)
                   (breakout-lop a-brkt))))

; render : Breakout -> Breakout
; a rendered breakout game 'a-brkt'
(define (render a-brkt)
  (render-balls (breakout-loba a-brkt)
                (render-bricks (breakout-lobr a-brkt)
                               (render-paddles (breakout-lop a-brkt)
                                               BG-IMG))))

; render-blocks : List<Block> Image -> Image
; an 'bg-img' with Blocks 'a-lob' placed on it
(define (render-bricks a-lobr bg-img)
  (cond
    [(empty? a-lobr) bg-img]
    [else
     (local (; first Brick in 'a-lobr'
             (define a-brick (first a-lobr)))
       (place-image (rectangle IBRICK-WIDTH
                               IBRICK-HEIGHT
                               "solid"
                               (row->color (brick-row a-brick)))
                    (+ (col->x (brick-col a-brick))
                       (/ BRICK-WIDTH 2))
                    (+ (row->y (brick-row a-brick))
                       (/ BRICK-HEIGHT 2))
                    (render-bricks (rest a-lobr) bg-img)))]))

; render-ball : Ball Image -> Image
; an 'bg-img' with Ball 'a-ball' placed on it
(define (render-balls a-loba bg-img)
  (cond
    [(empty? a-loba) bg-img]
    [else
     (local (; first Ball in 'a-loba'
             (define a-ball (first a-loba)))
       (place-image (square (* 2 BALL-RADIUS)
                            "solid"
                            "white")
                    (ball-x a-ball)
                    (ball-y a-ball)
                    (render-balls (rest a-loba) bg-img)))]))

; render-paddle : Paddle Image -> Image
; an 'bg-img' with Paddle 'a-paddle' placed on it
(define (render-paddles a-lop bg-img)
  (cond
    [(empty? a-lop) bg-img]
    [else
     (local (; first Paddle in 'a-lop'
             (define a-paddle (first a-lop)))
       (place-image (rectangle (- (paddle-width a-paddle) PF-SPACING)
                               IBRICK-HEIGHT
                               "solid"
                               (row->color (paddle-row a-paddle)))
                    (+ (paddle-x a-paddle)
                       (/ (paddle-width a-paddle) 2))
                    (+ (row->y (paddle-row a-paddle))
                       (/ IBRICK-HEIGHT 2))
                    (render-paddles (rest a-lop) bg-img)))]))

;; Main
;;;;;;;;

; run : Breakout -> Breakout
; run the breakout game with initial state 'a-brkt'
(define (run a-brkt)
  (big-bang a-brkt
    [on-tick update SPT]
    [state DEBUG?]
    [to-draw render]))

(run BREAKOUT0)
