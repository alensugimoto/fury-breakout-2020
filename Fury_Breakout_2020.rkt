;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname Fury_Breakout_2020) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))

;; TODO
; validate line-circle-intersection points with a rectangles
; instead of passing x1 y1 x2 y2, pass sx0 sy0 vx vy or just s0 v

;; MAIN ALGORITHM
; For every tick,
; - find the closest Collision (point and normal)
; - remove the block(s) that is on the point.
; - move the ball to the exact collision point and use the normal to flip directions
; - recursively call update with the time remaining

;;; Libraries

; a library for drawing images
(require 2htdp/image)
; a library for making an interactive program
(require 2htdp/universe)
; a library for creating sounds
(require rsound)

;;; Constants

; seconds per clock tick
(define SPT 0.02)
; whether to debug or not
(define DEBUG? #false)

; width of the canvas in pixels
(define CNVS-WIDTH 240)
; height of the canvas in pixels
(define CNVS-HEIGHT 800)

; ball radius in pixels
(define BALL-RADIUS 5)
; ball color
(define BALL-COLOR "red")
; ball speed
(define BALL-SPEED 3)

; wall thickness in pixels
(define WALL-THICKNESS 0)

; block width in pixels
(define BLOCK-WIDTH 30)
; block height in pixels
(define BLOCK-HEIGHT 20)
; block color
(define BLOCK-COLOR "blue")
; gap between blocks
(define GAP 4)

; paddle vertical position
(define PADDLE-SY 600)
; paddle height
(define PADDLE-HEIGHT 10)
; paddle color
(define PADDLE-COLOR "green")
; paddle speed
(define PADDLE-SPEED 6)
; paddle width
(define PADDLE-WIDTH 80)

;;; Derived constants

; background image
(define BG-IMG (empty-scene CNVS-WIDTH CNVS-HEIGHT))
; ball image
(define BALL-IMG (circle BALL-RADIUS "solid" BALL-COLOR))
; block image
(define BLOCK-IMG (rectangle BLOCK-WIDTH BLOCK-HEIGHT "solid" BLOCK-COLOR))
        
;;; Data types

; a NonnegativeNumber is a Number greater than or equal to zero
; interpretation: a non-negative number

; a NonnegativeInteger is one of the following:
; - 0                         ; zero
; - (add1 NonnegativeInteger) : a positive Integer
; interpretation: a non-negative integer

; a Posn is (make-posn Number Number)
; interpretation: a position vector ('x', 'y') in pixels
; (define-struct posn [x y])

; a Velo is (make-velo Number Number)
; interpretation: a velocity vector ('x', 'y') in pixels per clock tick
(define-struct velo [x y])

; a Normal is (make-normal Number Number)
; interpretation: a normal vector ('x', 'y')
(define-struct normal [x y])

; a Ball is (make-ball Posn Velo)
; interpretation: a ball with position 's' and velocity 'v'
(define-struct ball [s v paddle-hit-count])

; a Wall is (make-wall Posn NonnegativeNumber NonnegativeNumber)
; interpretation: a wall at position 's' with width 'w' and height 'h' in pixels
(define-struct wall [s w h])

; a Block is (make-block Posn)
; interpretation: a block at position 's'
(define-struct block [s])

; a Paddle is (make-paddle Number Number NonnegativeNumber)
; interpretation: a paddle with horizontal position 'sx',
;                 horizontal velocity 'vx', and
;                 width 'w' in pixels
(define-struct paddle [sx vx w])

; a BallObstacle is one of the following:
; - Wall
; - Block
; - Paddle
; interpretation: an object that a Ball can collide with

; a Collision is (make-collision Number Normal BallObstacle)
; interpretation: a collision, which occurs a fraction 't' of the way to
;                 the final position of a ball if there weren't any collisions,
;                 with normal 'n' between a Ball and a BallObstacle
(define-struct collision [t n obstacle])

; a Breakout is (make-breakout Ball List<Block>)
(define-struct breakout [ball lob paddle score progression-count])

;;; Data examples

; Walls
(define LEFT-WALL
  (make-wall (make-posn 0 0) WALL-THICKNESS CNVS-HEIGHT))
(define TOP-WALL
  (make-wall (make-posn 0 0) CNVS-WIDTH WALL-THICKNESS))
(define RIGHT-WALL
  (make-wall (make-posn (- CNVS-WIDTH WALL-THICKNESS) 0) WALL-THICKNESS CNVS-HEIGHT))
(define BOTTOM-WALL
  (make-wall (make-posn 0 (- CNVS-HEIGHT WALL-THICKNESS)) CNVS-WIDTH WALL-THICKNESS))

; Blocks
(define BLOCK0 (make-block (make-posn 0 0)))
(define BLOCK1 (make-block (make-posn 100 0)))
(define BLOCK2 (make-block (make-posn 0 50)))
(define BLOCK3 (make-block (make-posn 100 50)))
(define BLOCK4 (make-block (make-posn 0 100)))
(define BLOCK5 (make-block (make-posn 100 100)))

; Paddle
(define PADDLE0 (make-paddle 100 0 PADDLE-WIDTH))

; List<Wall>
(define LOW0 (list LEFT-WALL TOP-WALL RIGHT-WALL BOTTOM-WALL))

; List<Block>
(define NEW-BLOCKS (list (make-block (make-posn 0 0))
                         (make-block (make-posn 30 0))
                         (make-block (make-posn 60 0))
                         (make-block (make-posn 90 0))
                         (make-block (make-posn 120 0))
                         (make-block (make-posn 150 0))
                         (make-block (make-posn 180 0))
                         (make-block (make-posn 210 0))
                         (make-block (make-posn 240 0))))
(define LOB0 (append NEW-BLOCKS
                     (map (lambda (a-block)
                          (make-block (make-posn (posn-x (block-s a-block))
                                                 (+ BLOCK-HEIGHT GAP (posn-y (block-s a-block))))))
                          NEW-BLOCKS)
                     (map (lambda (a-block)
                          (make-block (make-posn (posn-x (block-s a-block))
                                                 (+ (* 2 (+ BLOCK-HEIGHT GAP)) (posn-y (block-s a-block))))))
                        NEW-BLOCKS)
                     (map (lambda (a-block)
                          (make-block (make-posn (posn-x (block-s a-block))
                                                 (+ (* 3 (+ BLOCK-HEIGHT GAP)) (posn-y (block-s a-block))))))
                        NEW-BLOCKS)
                     (map (lambda (a-block)
                          (make-block (make-posn (posn-x (block-s a-block))
                                                 (+ (* 7 (+ BLOCK-HEIGHT GAP)) (posn-y (block-s a-block))))))
                        NEW-BLOCKS)
                     (map (lambda (a-block)
                          (make-block (make-posn (posn-x (block-s a-block))
                                                 (+ (* 8 (+ BLOCK-HEIGHT GAP)) (posn-y (block-s a-block))))))
                        NEW-BLOCKS)
                     (map (lambda (a-block)
                          (make-block (make-posn (posn-x (block-s a-block))
                                                 (+ (* 9 (+ BLOCK-HEIGHT GAP)) (posn-y (block-s a-block))))))
                        NEW-BLOCKS)
                     (map (lambda (a-block)
                          (make-block (make-posn (posn-x (block-s a-block))
                                                 (+ (* 10 (+ BLOCK-HEIGHT GAP)) (posn-y (block-s a-block))))))
                        NEW-BLOCKS)))

; Ball
(define BALL0 (make-ball (make-posn 50 300) (make-velo (* BALL-SPEED (sqrt 2)) (* BALL-SPEED (sqrt 2))) 0))

; Breakout
(define BREAKOUT0 (make-breakout BALL0 LOB0 PADDLE0 0 0))

;;; Functions

; breakout-loo : Breakout -> List<BallObstacle>
; a list of BallObstacles in 'a-brkt'
(define (breakout-loo a-brkt)
  (cons (breakout-paddle a-brkt)
        (append (breakout-lob a-brkt)
                LOW0)))

; filtered-obstacles : Number Number Number Number List<BallObstacle> -> List<BallObstacle>
; a sublist of a list of BallObstacles, 'loo', that may be intersected by
;    a line segment from ('x1', 'y1') to ('x2', 'y2')
(define (filtered-obstacles x1 y1 x2 y2 loo)
  (local ((define x-1 (min x1 x2))
          (define x-2 (max x1 x2))
          (define y-1 (min y1 y2))
          (define y-2 (max y1 y2))
          (define (may-collide? left top right bottom)
            (and (>= x-2 (- left BALL-RADIUS))
                 (>= (+ right BALL-RADIUS) x-1)
                 (>= y-2 (- top BALL-RADIUS))
                 (>= (+ bottom BALL-RADIUS) y-1))))
    (filter (lambda (a-obst)
            (cond
              [(wall? a-obst)
               (may-collide? (posn-x (wall-s a-obst))
                             (posn-y (wall-s a-obst))
                             (+ (posn-x (wall-s a-obst))
                                (wall-w a-obst))
                             (+ (posn-y (wall-s a-obst))
                                (wall-h a-obst)))]
              [(block? a-obst)
               (may-collide? (posn-x (block-s a-obst))
                             (posn-y (block-s a-obst))
                             (+ (posn-x (block-s a-obst))
                                BLOCK-WIDTH)
                             (+ (posn-y (block-s a-obst))
                                BLOCK-HEIGHT))]
              [(paddle? a-obst)
               (may-collide? (paddle-sx a-obst)
                             PADDLE-SY
                             (+ (paddle-sx a-obst)
                                (paddle-w a-obst))
                             (+ PADDLE-SY
                                PADDLE-HEIGHT))]))
            loo)))

; line-collision : Number Number Number Number BallObstacle -> Maybe<Collision>
; a Collision between a BallObstacle, 'a-obst',
;    and a line segment from ('x1', 'y1') to ('x2', 'y2')
(define (line-collision x1 y1 x2 y2 a-obst)
  (cond
    [(wall? a-obst)
     (line-rrect-collision x1 y1 x2 y2
                           (posn-x (wall-s a-obst))
                           (posn-y (wall-s a-obst))
                           (+ (posn-x (wall-s a-obst))
                              (wall-w a-obst))
                           (+ (posn-y (wall-s a-obst))
                              (wall-h a-obst))
                           a-obst)]
    [(block? a-obst)
     (line-rrect-collision x1 y1 x2 y2
                           (posn-x (block-s a-obst))
                           (posn-y (block-s a-obst))
                           (+ (posn-x (block-s a-obst))
                              BLOCK-WIDTH)
                           (+ (posn-y (block-s a-obst))
                              BLOCK-HEIGHT)
                           a-obst)]
    [(paddle? a-obst)
     (line-rpaddle-collision x1 y1 x2 y2
                             (paddle-sx a-obst)
                             PADDLE-SY
                             (+ (paddle-sx a-obst)
                                (paddle-w a-obst))
                             (+ PADDLE-SY
                                PADDLE-HEIGHT)
                             a-obst)]))

;; Tick handling
;;;;;;;;;;;;;;;;;

; next-ball-collision : Ball List<BallObstacle> NonnegativeNumber -> Maybe<Collision>
; a list of the next simultaneously-occurring Collisions
;    between a Ball and a BallObstacle in 'a-brkt'
;    during the next 'delta-t' clock ticks
(define (next-ball-collision a-ball a-loo delta-t)
  (local (; the current position of 'a-ball'
          (define s0 (ball-s a-ball))
          ; the position of 'a-ball' after 'delta-t' clocks ticks,
          ;    given that there are no collisions
          (define s (get-s s0 (ball-v a-ball) delta-t))
          ; x- and y-components of 's0'
          (define x1 (posn-x s0))
          (define y1 (posn-y s0))
          ; x- and y-components of 's'
          (define x2 (posn-x s))
          (define y2 (posn-y s))
          ; a list of BallObstacles that may collide with the Ball
          (define filtered-loo (filtered-obstacles x1 y1 x2 y2 a-loo)))
    (next-line-collision x1 y1 x2 y2 filtered-loo)))

; next-line-collisions : Number Number Number Number List<BallObstacle> -> Maybe<Collision>
; a list of the next simultaneously-occurring Collisions
;    between a line segment from ('x1', 'y1') to ('x2', 'y2')
;    and a BallObstacle in 'a-brkt'
(define (next-line-collision x1 y1 x2 y2 a-loo)
  (nearest-collision (all-line-collisions x1 y1 x2 y2 a-loo)))

; all-line-collisions : Number Number Number Number Breakout -> List<Collision>
; a list of the all Collisions
;    between a line segment from ('x1', 'y1') to ('x2', 'y2')
;    and a BallObstacle in 'a-brkt'
(define (all-line-collisions x1 y1 x2 y2 a-loo)
  (remove-all #false
              (map (lambda (a-obst)
                     (line-collision x1 y1 x2 y2 a-obst))
                   a-loo)))

; nearest-collision : List<Collision> -> Maybe<Collision>
; a list of Collisions that have the smallest parametric value 
(define (nearest-collision loc)
  (cond
    [(empty? loc) #false]
    [else (argmin collision-t loc)]))

;;; 

; line-rpaddle-collision : Number Number Number Number Number Number Number Number BallObstacle -> Maybe<Collision>
; a Posn representing the intersection points between
;    a line segment from ('x1', 'y1') to ('x2', 'y2') and
;    a rounded paddle with 'left', 'top', 'right', and 'bottom' sides
(define (line-rpaddle-collision x1 y1 x2 y2 left top right bottom a-obst)
  (local ((define w (paddle-w a-obst))
          (define h PADDLE-HEIGHT)
          (define r (paddle-r a-obst)))
    (cond
      [(< h (/ w 2))
       (local ((define t-bottom (if (< y2 y1)
                                    (line-line-intercept x1 y1 x2 y2
                                                         left
                                                         (+ bottom BALL-RADIUS)
                                                         right
                                                         (+ bottom BALL-RADIUS))
                                    #false))
               (define t-bottom-left (line-arc-intercept x1 y1 x2 y2
                                                         left bottom BALL-RADIUS
                                                         (lambda (a)
                                                           (or (<= (/ pi 2) a pi)
                                                               (<= (- pi)
                                                                   a
                                                                   (- (/ (- pi (acos (- 1 (/ (* w w) (* 2 r r))))) 2) pi))))))
               (define t-bottom-right (line-arc-intercept x1 y1 x2 y2
                                                          right bottom BALL-RADIUS
                                                          (lambda (a)
                                                            (<= (- (/ (- pi (acos (- 1 (/ (* w w) (* 2 r r))))) 2))
                                                                a
                                                                (/ pi 2)))))
               (define t-top (line-arc-intercept x1 y1 x2 y2
                                                 (/ (+ left right) 2) (+ PADDLE-SY r) (+ r BALL-RADIUS)
                                                 (lambda (a)
                                                   (<= (- (/ (- pi (acos (- 1 (/ (* w w) (* 2 r r))))) 2) pi)
                                                       a
                                                       (- (/ (- pi (acos (- 1 (/ (* w w) (* 2 r r))))) 2))))))
               (define (make-this-ob-collision a-t a-n)
                 (make-collision a-t a-n a-obst))
               (define (check-normal a-normal)
                 (if (false? a-normal) #false
                     (local ((define vx (- x2 x1))
                             (define vy (- y2 y1))
                             (define nx (normal-x a-normal))
                             (define ny (normal-y a-normal))
                             (define dot (+ (* vx nx) (* vy ny))))
                  (if (negative? dot) a-normal #false))))
               (define (make-new-normal a-t cx cy)
                 (if (false? a-t)
                #false
                (make-normal (- (+ x1 (* a-t (- x2 x1))) cx)
                             (- (+ y1 (* a-t (- y2 y1))) cy))))
               (define loc (filter (lambda (a-collision)
                                     (and (not (false? (collision-t a-collision)))
                                          (not (false? (collision-n a-collision)))))
                                   (list (make-this-ob-collision t-bottom
                                                                 (check-normal (make-normal 0 1)))
                                         (make-this-ob-collision t-top
                                                                 (check-normal (make-new-normal t-top (/ (+ left right) 2) (+ PADDLE-SY r))))
                                         (make-this-ob-collision t-bottom-left
                                                                 (check-normal (make-new-normal t-bottom-left left bottom)))
                                         (make-this-ob-collision t-bottom-right
                                                                 (check-normal (make-new-normal t-bottom-right right bottom)))))))
         (nearest-collision loc))]
      [(= h w)
       (local ((define t-top (line-arc-intercept x1 y1 x2 y2
                                                 (/ (+ left right) 2) (+ PADDLE-SY r) (+ r BALL-RADIUS)
                                                 (lambda (a) #true)))
               (define (make-this-ob-collision a-t a-n)
                 (make-collision a-t a-n a-obst))
               (define (check-normal a-normal)
                 (if (false? a-normal) #false
                     (local ((define vx (- x2 x1))
                             (define vy (- y2 y1))
                             (define nx (normal-x a-normal))
                             (define ny (normal-y a-normal))
                             (define dot (+ (* vx nx) (* vy ny))))
                  (if (negative? dot) a-normal #false))))
               (define (make-new-normal a-t cx cy)
                 (if (false? a-t)
                #false
                (make-normal (- (+ x1 (* a-t (- x2 x1))) cx)
                             (- (+ y1 (* a-t (- y2 y1))) cy))))
               (define loc (filter (lambda (a-collision)
                                     (and (not (false? (collision-t a-collision)))
                                          (not (false? (collision-n a-collision)))))
                                   (list (make-this-ob-collision
                                          t-top (check-normal (make-new-normal t-top (/ (+ left right) 2) (+ PADDLE-SY r))))))))
         (nearest-collision loc))]
      [else
       (local ((define y (- r h))
               (define det (- (* r r) (* y y)))
               (define x3 (+ (- (sqrt det)) (/ (+ left right) 2)))
               (define x4 (+ (sqrt det) (/ (+ left right) 2)))
               (define t-bottom (if (< y2 y1)
                                    (line-line-intercept x1 y1 x2 y2
                                                         x3 (+ bottom BALL-RADIUS)
                                                         x4 (+ bottom BALL-RADIUS))
                                    #false))
               (define t-bottom-left (line-arc-intercept x1 y1 x2 y2
                                                         x3 bottom BALL-RADIUS
                                                         (lambda (a)
                                                           (<= (/ pi 2)
                                                               a
                                                               (- pi (/ (- pi (acos (- 1 (/ (* (- x4 x3) (- x4 x3)) (* 2 r r))))) 2))))))
               (define t-bottom-right (line-arc-intercept x1 y1 x2 y2
                                                          x4 bottom BALL-RADIUS
                                                          (lambda (a)
                                                            (<= (/ (- pi (acos (- 1 (/ (* (- x4 x3) (- x4 x3)) (* 2 r r))))) 2)
                                                                a
                                                                (/ pi 2)))))
               (define t-top (line-arc-intercept x1 y1 x2 y2
                                                 (/ (+ left right) 2) (+ PADDLE-SY r) (+ r BALL-RADIUS)
                                                 (lambda (a)
                                                   (not (<= (/ (- pi (acos (- 1 (/ (* (- x4 x3) (- x4 x3)) (* 2 r r))))) 2)
                                                            a
                                                            (- pi (/ (- pi (acos (- 1 (/ (* (- x4 x3) (- x4 x3)) (* 2 r r))))) 2)))))))
               (define (make-this-ob-collision a-t a-n)
                 (make-collision a-t a-n a-obst))
               (define (check-normal a-normal)
                 (if (false? a-normal) #false
                     (local ((define vx (- x2 x1))
                             (define vy (- y2 y1))
                             (define nx (normal-x a-normal))
                             (define ny (normal-y a-normal))
                             (define dot (+ (* vx nx) (* vy ny))))
                  (if (negative? dot) a-normal #false))))
               (define (make-new-normal a-t cx cy)
                 (if (false? a-t)
                #false
                (make-normal (- (+ x1 (* a-t (- x2 x1))) cx)
                             (- (+ y1 (* a-t (- y2 y1))) cy))))
               (define loc (filter (lambda (a-collision)
                                     (and (not (false? (collision-t a-collision)))
                                          (not (false? (collision-n a-collision)))))
                                   (list (make-this-ob-collision t-bottom
                                                                 (check-normal (make-normal 0 1)))
                                         (make-this-ob-collision t-top
                                                                 (check-normal (make-new-normal t-top (/ (+ left right) 2) (+ PADDLE-SY r))))
                                         (make-this-ob-collision t-bottom-left
                                                                 (check-normal (make-new-normal t-bottom-left x3 bottom)))
                                         (make-this-ob-collision t-bottom-right
                                                                 (check-normal (make-new-normal t-bottom-right x4 bottom)))))))
         (nearest-collision loc))])))

; line-rrect-collision : Number Number Number Number Number Number Number Number BallObstacle -> Maybe<Collision>
; find the Collision between a line segment going from ('x1', 'y1') to ('x2', 'y2')
;    and a rectangle with top-left point of ('x1', 'y1') and bottom-right point of ('x2', 'y2')
(define (line-rrect-collision x1 y1 x2 y2 left top right bottom a-obst)
  (local ((define t-right (if (< x2 x1)
                              (line-line-intercept x1 y1 x2 y2
                                                   (+ right BALL-RADIUS)
                                                   top
                                                   (+ right BALL-RADIUS)
                                                   bottom)
                              #false))
          (define t-left (if (> x2 x1)
                             (line-line-intercept x1 y1 x2 y2
                                                  (- left BALL-RADIUS)
                                                  top
                                                  (- left BALL-RADIUS)
                                                  bottom)
                             #false))
          (define t-bottom (if (and (false? t-left)
                                    (false? t-right)
                                    (< y2 y1))
                               (line-line-intercept x1 y1 x2 y2
                                                    left
                                                    (+ bottom BALL-RADIUS)
                                                    right
                                                    (+ bottom BALL-RADIUS))
                               #false))
          (define t-top (if (and (false? t-left)
                                 (false? t-right)
                                 (> y2 y1))
                            (line-line-intercept x1 y1 x2 y2
                                                 left
                                                 (- top BALL-RADIUS)
                                                 right
                                                 (- top BALL-RADIUS))
                            #false))
          (define t-top-left (if (and (false? t-left)
                                      (false? t-right)
                                      (false? t-top)
                                      (false? t-bottom)
                                      (or (> y2 y1) (> x2 x1)))
                                 (line-arc-intercept x1 y1 x2 y2
                                                     left top BALL-RADIUS
                                                     (lambda (a)
                                                       (<= (- pi) a (/ pi -2))))
                                 #false))
          (define t-top-right (if (and (false? t-left)
                                       (false? t-right)
                                       (false? t-top)
                                       (false? t-bottom)
                                       (or (> y2 y1) (< x2 x1)))
                                  (line-arc-intercept x1 y1 x2 y2
                                                      right top BALL-RADIUS
                                                      (lambda (a)
                                                        (<= (/ pi -2) a 0)))
                                  #false))
          (define t-bottom-left (if (and (false? t-left)
                                         (false? t-right)
                                         (false? t-top)
                                         (false? t-bottom)
                                         (or (< y2 y1) (> x2 x1)))
                                    (line-arc-intercept x1 y1 x2 y2
                                                        left bottom BALL-RADIUS
                                                        (lambda (a)
                                                          (<= (/ pi 2) a pi)))
                                    #false))
          (define t-bottom-right (if (and (false? t-left)
                                          (false? t-right)
                                          (false? t-top)
                                          (false? t-bottom)
                                          (or (< y2 y1) (< x2 x1)))
                                     (line-arc-intercept x1 y1 x2 y2
                                                         right bottom BALL-RADIUS
                                                         (lambda (a)
                                                           (<= 0 a (/ pi 2))))
                                     #false))
          (define (make-this-ob-collision a-t a-n)
            (make-collision a-t a-n a-obst))
          (define (check-normal a-normal)
            (if (false? a-normal) #false
                (local ((define vx (- x2 x1))
                        (define vy (- y2 y1))
                        (define nx (normal-x a-normal))
                        (define ny (normal-y a-normal))
                        (define dot (+ (* vx nx) (* vy ny))))
                  (if (negative? dot) a-normal #false))))
          (define (make-new-normal a-t cx cy)
            (if (false? a-t)
                #false
                (make-normal (- (+ x1 (* a-t (- x2 x1))) cx)
                             (- (+ y1 (* a-t (- y2 y1))) cy))))
          (define loc (filter (lambda (a-collision)
                      (and (not (false? (collision-t a-collision)))
                           (not (false? (collision-n a-collision)))))
                    (list (make-this-ob-collision t-left
                                                  (check-normal (make-normal -1 0)))
                          (make-this-ob-collision t-right
                                                  (check-normal (make-normal 1 0)))
                          (make-this-ob-collision t-top
                                                  (check-normal (make-normal 0 -1)))
                          (make-this-ob-collision t-bottom
                                                  (check-normal (make-normal 0 1)))
                          (make-this-ob-collision t-top-left
                                                  (check-normal (make-new-normal t-top-left left top)))
                          (make-this-ob-collision t-top-right
                                                  (check-normal (make-new-normal t-top-right right top)))
                          (make-this-ob-collision t-bottom-left
                                                  (check-normal (make-new-normal t-bottom-left left bottom)))
                          (make-this-ob-collision t-bottom-right
                                                  (check-normal (make-new-normal t-bottom-right right bottom)))))))
    (nearest-collision loc)))

;  (local ((define (fun-y)
;            (cond
;              [(< y2 y1)
;               (if (false? (intercept x1 y1 x2 y2
;                                      (- left BALL-RADIUS)
;                                      (+ bottom BALL-RADIUS)
;                                      (+ right BALL-RADIUS)
;                                      (+ bottom BALL-RADIUS)))
;                   #false
;                   (make-collision (intercept x1 y1 x2 y2
;                                              (- left BALL-RADIUS)
;                                              (+ bottom BALL-RADIUS)
;                                              (+ right BALL-RADIUS)
;                                              (+ bottom BALL-RADIUS))
;                                   "bottom" obstacle))]
;              [(> y2 y1)
;               (if (false? (intercept x1 y1 x2 y2
;                                           (- left BALL-RADIUS)
;                                           (- top BALL-RADIUS)
;                                           (+ right BALL-RADIUS)
;                                           (- top BALL-RADIUS)))
;                   #false
;                   (make-collision (intercept x1 y1 x2 y2
;                                           (- left BALL-RADIUS)
;                                           (- top BALL-RADIUS)
;                                           (+ right BALL-RADIUS)
;                                           (- top BALL-RADIUS))
;                                "top" obstacle))]
;              [else #false])))
;    (cond
;      [(< x2 x1)
;       (if (false? (intercept x1 y1 x2 y2
;                                           (+ right BALL-RADIUS)
;                                           (- top BALL-RADIUS)
;                                           (+ right BALL-RADIUS)
;                                           (+ bottom BALL-RADIUS)))
;         (fun-y)
;         (make-collision (intercept x1 y1 x2 y2
;                                    (+ right BALL-RADIUS)
;                                    (- top BALL-RADIUS)
;                                    (+ right BALL-RADIUS)
;                                    (+ bottom BALL-RADIUS))
;                         "right" obstacle))]
;      [(> x2 x1)
;       (if (false? (intercept x1 y1 x2 y2
;                                           (- left BALL-RADIUS)
;                                           (- top BALL-RADIUS)
;                                           (- left BALL-RADIUS)
;                                           (+ bottom BALL-RADIUS)))
;           (fun-y)
;           (make-collision (intercept x1 y1 x2 y2
;                                      (- left BALL-RADIUS)
;                                      (- top BALL-RADIUS)
;                                      (- left BALL-RADIUS)
;                                      (+ bottom BALL-RADIUS))
;                                "left" obstacle))]
;      [else (fun-y)])))

; intercept : Number Number Number Number Number Number Number Number -> Maybe<Posn>
; try to find the point of intersection of two line segments
;    going from ('x1', 'y1') to ('x2', 'y2')
;    and from ('x3', 'y3') to ('x4', 'y4')
; header: (define (intercept x1 y1 x2 y2 x3 y3 x4 y4) (make-posn x1 y1))
(define (line-line-intercept x1 y1 x2 y2 x3 y3 x4 y4)
  (local ((define denom (- (* (- y4 y3) (- x2 x1))
                           (* (- x4 x3) (- y2 y1)))))
    (if (zero? denom)
        #false
        (local ((define t (/ (- (* (- x4 x3) (- y1 y3))
                                (* (- y4 y3) (- x1 x3)))
                             denom)))
          (if (not (<= 0 t 1))
              #false
              (local ((define u (/ (- (* (- x2 x1) (- y1 y3))
                                      (* (- y2 y1) (- x1 x3)))
                                   denom)))
                (if (not (<= 0 u 1))
                    #false
                    t)))))))

; line-circle-intercept : Number Number Number Number Number Number Number -> Maybe<Number>
(define (line-arc-intercept x1 y1 x2 y2 cx cy r fun)
  (local ((define v10 (- x2 x1))
          (define v11 (- y2 y1))
          (define v20 (- x1 cx))
          (define v21 (- y1 cy))
          (define a (+ (* v10 v10)
                       (* v11 v11)))
          (define b (* 2 (+ (* v10 v20)
                            (* v11 v21))))
          (define c (- (+ (* v20 v20)
                          (* v21 v21))
                       (* r r)))
          (define d (- (* b b) (* 4 a c)))
          (define (get-x a-t)
            (+ x1 (* a-t v10)))
          (define (get-y a-t)
            (+ y1 (* a-t v11)))
          (define (valid? a-t)
            (and (<= 0 a-t 1)
                 (fun (atan (- (get-y a-t) cy)
                            (- (get-x a-t) cx))))))
    (cond
      [(or (negative? d) (zero? a)) #false]
      [(zero? d)
       (local ((define t (/ (- b)
                            (* 2 a))))
         (if (valid? t) t #false))]
      [else
       (local ((define t1 (/ (- (- b) (sqrt d))
                             (* 2 a)))
               (define t2 (/ (+ (- b) (sqrt d))
                             (* 2 a))))
         (cond
           [(and (valid? t1) (valid? t2))
            (if (< t1 t2) t1 t2)]
           [(valid? t1) t1]
           [(valid? t2) t2]
           [else #false]))])))

; get-s : Posn Velo NonnegativeNumber -> Posn
; calculate final Posn after 'delta-t' clock ticks
;    given initial Posn 's0' and Velo 'v'
; header: (define (get-s s0 v delta-t) s0)
(define (get-s s0 v delta-t)
  (make-posn (+ (posn-x s0) (* (velo-x v) delta-t))
             (+ (posn-y s0) (* (velo-y v) delta-t))))

; reflect : Velo Normal -> Velo
; reflect 'a-velo' off Normal 'a-normal'
(define (reflect a-velo a-normal)
  (local (; horizontal velocity of 'a-velo'
          (define vx (velo-x a-velo))
          ; vertical velocity of 'a-velo'
          (define vy (velo-y a-velo))
          ; normalize : Normal -> Normal
          ; calculates the normalized vector of 'n'
          (define (normalize n)
            (local (; x-component of 'n'
                    (define nx (normal-x n))
                    ; y-component of 'n'
                    (define ny (normal-y n))
                    ; norm of 'a-normal'
                    (define norm (sqrt (+ (expt nx 2)
                                          (expt ny 2)))))
              (make-normal (/ nx norm) (/ ny norm))))
          ; normalized vector of 'a-normal'
          (define n-hat (normalize a-normal))
          ; dot product of 'a-velo' and 'n-hat'
          (define dot (+ (* vx (normal-x n-hat))
                         (* vy (normal-y n-hat)))))
    (make-velo (- vx (* 2 dot (normal-x n-hat)))
               (- vy (* 2 dot (normal-y n-hat))))))

; update : Breakout -> Breakout
; update 'a-brkt0' for one clock tick
(define (update a-brkt0)
  (local (; update/acc : Breakout NonnegativeNumber -> Breakout
          ; update 'a-brkt' for 'delta-t' clock ticks
          ; header: (define (update/acc a-brkt delta-t) a-brkt)
          (define (update/acc a-brkt delta-t)
            (local (; current Ball in 'a-brkt'
                    (define a-ball (breakout-ball a-brkt))
                    ; current Blocks in 'a-brkt'
                    (define a-lob (breakout-lob a-brkt))
                    ; current Paddle in 'a-brkt'
                    (define a-paddle (breakout-paddle a-brkt))
                    ; current score in 'a-brkt'
                    (define a-score (breakout-score a-brkt))
                    ; current progression-count in 'a-brkt'
                    (define a-progression-count (breakout-progression-count a-brkt))
                    ; 'a-ball' initial position
                    (define s0 (ball-s a-ball))
                    ; 'a-ball' velocity
                    (define v (ball-v a-ball))
                    ; a list of BallObstacles
                    (define a-loo (breakout-loo a-brkt))
                    ; a list of the next simultaneously-occurring Collisions
                    ;    between 'a-ball' and a BallObstacle in 'delta-t' ticks
                    (define a-collision (next-ball-collision a-ball a-loo delta-t))
                    ; 'a-ball' final position without collisions
                    (define s (get-s s0 v delta-t)))
              (cond
                [(false? a-collision) ; no collisions
                 (make-breakout (make-ball s v (ball-paddle-hit-count a-ball)) a-lob a-paddle a-score a-progression-count)]
                [else                 ; at least one collision
                 (andplay ding
                          (update/acc (make-breakout (update-ball a-ball delta-t a-collision)
                                                     (update-blocks a-lob a-ball a-progression-count a-collision)
                                                     (update-paddle a-paddle a-collision)
                                                     (update-score a-score a-collision)
                                                     (update-progression-count a-progression-count a-ball a-collision))
                                      (* delta-t (- 1 (collision-t a-collision)))))]))))
    (update/acc (move-paddle a-brkt0) 1)))

; update-paddle : Paddle Collision -> Paddle
(define (update-paddle a-paddle a-collision)
  (cond
    [(and (equal? TOP-WALL (collision-obstacle a-collision))
          (= PADDLE-WIDTH (paddle-w a-paddle)))
     (make-paddle (paddle-sx a-paddle)
                  (paddle-vx a-paddle)
                  (/ PADDLE-WIDTH 2))]
    [else a-paddle]))

(define (update-progression-count a-progression-count a-ball a-collision)
  (if (and (paddle? (collision-obstacle a-collision))
           (or (and (<= 55 (ball-paddle-hit-count a-ball))
                    (= 0 (modulo (ball-paddle-hit-count a-ball) 1)))
               (and (<= 23 (ball-paddle-hit-count a-ball))
                    (= 1 (modulo (ball-paddle-hit-count a-ball) 2)))
               (and (<= 7 (ball-paddle-hit-count a-ball))
                    (= 3 (modulo (ball-paddle-hit-count a-ball) 4)))
               (and (<= -1 (ball-paddle-hit-count a-ball))
                    (= 7 (modulo (ball-paddle-hit-count a-ball) 8)))))
      (add1 a-progression-count)
      a-progression-count))

; update-score : NonnegativeInteger Collision -> NonnegativeInteger
(define (update-score a-score a-collision)
  (cond
    [(block? (collision-obstacle a-collision))
     (+ a-score
        (local ((define y (posn-y (block-s (collision-obstacle a-collision))))
                (define (get-y q)
                  (* CNVS-HEIGHT q)))
          (cond
            [(and (<= (get-y 0/8) y)
                  (< y (get-y 1/8)))
             7]
            [(and (<= (get-y 1/8) y)
                  (< y (get-y 2/8)))
             5]
            [(and (<= (get-y 2/8) y)
                  (< y (get-y 3/8)))
             3]
            [(and (<= (get-y 3/8) y)
                  (< y (get-y 4/8)))
             1]
            [(and (<= (get-y 4/8) y)
                  (< y (get-y 8/8)))
             1]
            [else
             0])))]
    [else a-score]))

;(define CELL-HEIGHT 20)
;(define CELL-WIDTH 40)
;
;(define (grid->list a-loloc0)
;  (local ((define (grid->list/acc row a-loloc)
;            (cond
;              [(empty? a-loloc) '()]
;              [else
;               (append (row->list row (first a-loloc))
;                       (grid->list/acc (add1 row) (rest a-loloc)))])))
;    (grid->list/acc 0 a-loloc0)))
;
;(define (row->list row a-loc0)
;  (local (; row->list/acc : NonnegativeInteger List<Cell> -> List<Block>
;          (define (row->list/acc cell a-loc)
;            (cond
;              [(empty? a-loc) '()]
;              [else
;               (if (zero? (first a-loc))
;                   (row->list/acc (add1 cell) (rest a-loc))
;                   (cons (make-block (make-posn (* cell CELL-WIDTH) (* row CELL-HEIGHT)))
;                         (row->list/acc (add1 cell) (rest a-loc))))])))
;    (row->list/acc 0 a-loc0)))

; update-blocks : List<Block> Ball Paddle Collision -> List<Block>
(define (update-blocks a-lob a-ball a-progression-count a-collision)
  (local ((define new-lob (remove-all (collision-obstacle a-collision) a-lob))
          (define progressed-lob
            (cond
              [(<= 0 (modulo a-progression-count 8) 3)
               '()]
              [else
               NEW-BLOCKS]))
          (define (progress a-lob)
            (make-block (make-posn (posn-x (block-s a-lob))
                                   (+ BLOCK-HEIGHT GAP (posn-y (block-s a-lob))))))
          (define (not-low? a-lob)
            (> PADDLE-SY (posn-y (block-s a-lob))))
          (define progress?
            (if (paddle? (collision-obstacle a-collision))
                (or (and (<= 55 (ball-paddle-hit-count a-ball))
                         (= 0 (modulo (ball-paddle-hit-count a-ball) 1)))
                    (and (<= 23 (ball-paddle-hit-count a-ball))
                         (= 1 (modulo (ball-paddle-hit-count a-ball) 2)))
                    (and (<= 7 (ball-paddle-hit-count a-ball))
                         (= 3 (modulo (ball-paddle-hit-count a-ball) 4)))
                    (and (<= -1 (ball-paddle-hit-count a-ball))
                         (= 7 (modulo (ball-paddle-hit-count a-ball) 8))))
                #false)))
    (cond
      [progress?
       (filter not-low? (append progressed-lob
                                (map progress new-lob)))]
      [else new-lob])))

; update-ball : Ball NonnegativeNumber Collision -> Ball
(define (update-ball a-ball delta-t a-collision)
  (local ((define t (collision-t a-collision))
          ; 'a-ball' initial position
          (define s0 (ball-s a-ball))
          ; 'a-ball' velocity
          (define v (ball-v a-ball))
          ; 'a-ball' final position without collisions
          (define s (get-s s0 v delta-t))
          ; 'a-ball' final position (collision point)
          (define new-s
            (make-posn (+ (posn-x s0) (* t (- (posn-x s) (posn-x s0))))
                       (+ (posn-y s0) (* t (- (posn-y s) (posn-y s0))))))
          ; 'a-ball' velocity after collision
          (define new-v (reflect v (collision-n a-collision)))
          ; 'a-ball' paddle hit count after collision
          (define new-paddle-hit-count
            (cond
              [(paddle? (collision-obstacle a-collision))
               (add1 (ball-paddle-hit-count a-ball))]
              [else (ball-paddle-hit-count a-ball)]))
          ; normalize : Normal -> Normal
          ; calculates the normalized vector of 'n'
          (define (normalize n)
            (local (; x-component of 'n'
                    (define nx (velo-x n))
                    ; y-component of 'n'
                    (define ny (velo-y n))
                    ; norm of 'a-normal'
                    (define norm (sqrt (+ (expt nx 2)
                                          (expt ny 2)))))
              (make-velo (/ nx norm) (/ ny norm))))
          (define mag (sqrt (+ (* (velo-x new-v) (velo-x new-v))
                               (* (velo-y new-v) (velo-y new-v)))))
          ; 'a-ball' velocity after collision
          (define new-new-v
            (cond
              [(block? (collision-obstacle a-collision))
               (local ((define y (posn-y (block-s (collision-obstacle a-collision))))
                       (define (get-y q)
                         (* CNVS-HEIGHT q)))
                 (cond
                   [(and (<= (get-y 0/8) y)
                         (< y (get-y 2/8)))
                    (make-velo (* 3 BALL-SPEED (velo-x (normalize new-v)))
                               (* 3 BALL-SPEED (velo-y (normalize new-v))))]
                   [else new-v]))]
              [(paddle? (collision-obstacle a-collision))
               (cond
                 [(and (= 12 new-paddle-hit-count)
                       (< mag (* 2.5 BALL-SPEED)))
                  (make-velo (* 2.5 BALL-SPEED (velo-x (normalize new-v)))
                             (* 2.5 BALL-SPEED (velo-y (normalize new-v))))]
                 [(and (= 8 new-paddle-hit-count)
                       (< mag (* 2 BALL-SPEED)))
                  (make-velo (* 2 BALL-SPEED (velo-x (normalize new-v)))
                             (* 2 BALL-SPEED (velo-y (normalize new-v))))]
                 [(and (= 4 new-paddle-hit-count)
                       (< mag (* 1.5 BALL-SPEED)))
                  (make-velo (* 1.5 BALL-SPEED (velo-x (normalize new-v)))
                             (* 1.5 BALL-SPEED (velo-y (normalize new-v))))]
                 [else new-v])]
              [else new-v])))
    (make-ball new-s new-new-v new-paddle-hit-count)))

; move-paddle : Breakout -> Breakout
; a Breakout with a moved paddle
(define (move-paddle a-brkt)
  (local ((define a-paddle (breakout-paddle a-brkt))
          (define new-sx (+ (paddle-sx a-paddle)
                            (paddle-vx a-paddle))))
    (make-breakout (breakout-ball a-brkt)
                   (breakout-lob a-brkt)
                   (make-paddle (max 0 (min (- CNVS-WIDTH (paddle-w a-paddle)) new-sx))
                                (paddle-vx a-paddle)
                                (paddle-w a-paddle))
                   (breakout-score a-brkt)
                   (breakout-progression-count a-brkt))))

; set-paddle-vx : Number Breakout -> Breakout
(define (set-paddle-vx vx a-brkt)
  (local ((define a-paddle (breakout-paddle a-brkt)))
    (make-breakout (breakout-ball a-brkt)
                   (breakout-lob a-brkt)
                   (make-paddle (paddle-sx a-paddle)
                                vx
                                (paddle-w a-paddle))
                   (breakout-score a-brkt)
                   (breakout-progression-count a-brkt))))

;; Rendering
;;;;;;;;;;;;;

; render : Breakout -> Breakout
; a rendered breakout game 'a-brkt'
(define (render a-brkt)
  (render-ball (breakout-ball a-brkt)
               (render-paddle (breakout-paddle a-brkt)
                              (render-blocks (breakout-lob a-brkt)
                                             BG-IMG))))

; render-blocks : List<Block> Image -> Image
; an 'bg-img' with Blocks 'a-lob' placed on it
(define (render-blocks a-lob bg-img)
  (cond
    [(empty? a-lob) bg-img]
    [else
     (local (; position of first Block in 'a-lob'
             (define s (block-s (first a-lob))))
       (place-image BLOCK-IMG
                    (+ (posn-x s) (/ BLOCK-WIDTH 2))
                    (+ (posn-y s) (/ BLOCK-HEIGHT 2))
                    (render-blocks (rest a-lob) bg-img)))]))

; render-ball : Ball Image -> Image
; an 'bg-img' with Ball 'a-ball' placed on it
(define (render-ball a-ball bg-img)
  (place-image BALL-IMG
               (posn-x (ball-s a-ball))
               (posn-y (ball-s a-ball))
               bg-img))

; render-paddle : Paddle Image -> Image
; an 'bg-img' with Paddle 'a-paddle' placed on it
(define (render-paddle a-paddle bg-img)
  (place-image (crop/align "center"
                           "top"
                           (paddle-w a-paddle)
                           PADDLE-HEIGHT
                           (circle (paddle-r a-paddle)
                                   "solid"
                                   PADDLE-COLOR))
               (+ (paddle-sx a-paddle) (/ (paddle-w a-paddle) 2))
               (+ PADDLE-SY (/ PADDLE-HEIGHT 2))
               bg-img))

;; Key handling
;;;;;;;;;;;;;;;;

(define (handle-key a-brkt key)
  (cond
    [(key=? key "left")
     (set-paddle-vx (- PADDLE-SPEED) a-brkt)]
    [(key=? key "right")
     (set-paddle-vx PADDLE-SPEED a-brkt)]
    [else a-brkt]))

(define (handle-release a-brkt key)
  (cond
    [(or (key=? key "left")
         (key=? key "right"))
     (set-paddle-vx 0 a-brkt)]
    [else a-brkt]))

;; Helpers
;;;;;;;;;;;

; paddle-r : Paddle -> NonnegativeNumber
; the radius of Paddle 'a-paddle'
(define (paddle-r a-paddle)
  (local (; width of 'a-paddle'
          (define w (paddle-w a-paddle))
          ; height of 'a-paddle'
          (define h PADDLE-HEIGHT))
    (cond
      [(< 0 h (/ w 2))
       (+ (/ h 2)
          (/ (* w w)
             (* 8 h)))]
      [(and (< 0 h) (<= h w))
       (/ w 2)]
      [else
       (error "invalid paddle dimensions")])))

;; Main
;;;;;;;;

; run : Breakout -> Breakout
; run the breakout game with initial state 'a-brkt'
(define (run a-brkt)
  (big-bang a-brkt
    [on-tick update SPT]
    [on-key handle-key]
    [on-release handle-release]
    [state DEBUG?]
    [to-draw render]))

(run BREAKOUT0)
