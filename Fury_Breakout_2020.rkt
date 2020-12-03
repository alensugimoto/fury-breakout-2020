;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname Fury_Breakout_2020) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))

;;; Libraries
;;;;;;;;;;;;;;

; a library for drawing images
(require 2htdp/image)
; a library for making an interactive program
(require 2htdp/universe)
; a library for reading a bitmap font file
(require 2htdp/batch-io)

;;; Data types
;;;;;;;;;;;;;;;

; a NonnegativeNumber is a Number greater than or equal to zero
; interpretation: a non-negative number

; a NonnegativeInteger is one of the following:
; - 0                         ; zero
; - (add1 NonnegativeInteger) : a positive Integer
; interpretation: a non-negative integer

; a Byte is a String containing the following 1-letter Strings:
; - "0"
; - "1"
; interpretation: string of an 8-bit number

; an Angle is a Number between (- pi) exclusive and pi inclusive
; interpretation: an angle in radians

; a Brick is (make-brick NonnegativeInteger NonnegativeInteger)
; interpretation: a brick in row number 'row' and column number 'col'
(define-struct brick [col row])

; a Paddle is (make-paddle x row speed dir width)
;    where x     : Number
;          row   : NonnegativeInteger
;          speed : NonnegativeNumber
;          dir   : Angle
;          width : NonnegativeNumber
; interpretation: a paddle with horizontal position 'x' in pixels,
;                 vertical position 'row' in rows,
;                 speed 'speed' in pixels per second,
;                 direction 'dir', and width 'width' in pixels
(define-struct paddle [x row speed dir width])

; a Backwall is (make-backwall)
; interpretation: a wall stretched over row number 0
(define-struct backwall [])

; a VObject is one of the following:
; - a Brick
; - a Paddle
; - a Backwall
; interpretation: an object that can rebound a ball vertically

; a Ball is (make-ball x y speed dir last-vobject paddle-hit-count)
;    where x, y             : Number
;          speed            : NonnegativeNumber
;          dir              : Angle
;          last-vobject     : VObject
;          paddle-hit-count : NonnegativeInteger
; interpretation: a ball, which most recently collided with 'last-vobject',
;                 with position ('x', 'y') in pixels,
;                 speed 'speed' in pixels per second,
;                 direction 'dir', and a paddle hit count of 'paddle-hit-count'
(define-struct ball [x y speed dir last-vobject tick-score paddle-hit-count serve-delay visible?])

; a CollisionGeometry is (make-collision-geometry Number Number Number Number)
; interpretation: a rectangle with top left corner positioned at ('left', 'top')
;                 and bottom right corner positioned at ('right', 'bottom') in pixels
(define-struct collision-geometry [left top right bottom])

; a ColorOverlay is (make color-overlay Color NonnegativeInteger NonnegativeInteger)
; interpretation: a color overlay applied over rows 'i' inclusive to 'j' exclusive
(define-struct color-overlay [c i j])

; a Game is one of the following Strings:
; - "double"
; - "cavity"
; - "progressive"
; interpretation: the name of one of the three Super Breakout games
;                 in Super Breakout

; an AttractVersion is either 1 or 2
; interpretation: an attract mode version in Super Breakout

; an Attract is (make-attract AttractVersion Game)
; interpretaton: a Super Breakout mode called "attract"
(define-struct attract [version game])

; a ReadyToPlay is (make-ready-to-play)
; interpretaton: a Super Breakout mode called "ready-to-play"
(define-struct ready-to-play [])

; a Play is (make-play)
; interpretaton: a Super Breakout mode called "play"
(define-struct play [])

; a Mode is one of the following Strings:
; - an Attract
; - a ReadyToPlay
; - a Play
; interpretation: one of the three different modes of operation
;                 in Super Breakout

; a ControlPanel is (make-ctrl-panel serve? paddle-posn game one-player? two-player?)
;    where serve?      : Boolean
;          paddle-posn : Number
;          game        : Game
;          one-player? : Boolean
;          two-player? : Boolean
; interpretation: a Super Breakout control panel
(define-struct ctrl-panel [serve? paddle-posn game one-player? two-player?])

; a Breakout is (make-breakout loba lobr lop score high-score credit-count second-count ctrl-panel mode)
;    where loba         : List<Ball>
;          lobr         : List<Brick>
;          lop          : List<Paddle>
;          score        : NonnegativeInteger
;          high-score   : NonnegativeInteger
;          credit-count : NonnegativeInteger
;          second-count : NonnegativeInteger
;          ctrl-panel   : ControlPanel
;          mode         : Mode
; interpretation: Super Breakout with Balls 'loba',
;                 Bricks 'lobr', Paddles 'lop', and
;                 current Mode of operation 'mode'
(define-struct breakout
  [loba lobr lop p1-score p2-score high-score credit-count second-count ctrl-panel mode])

;;; Constants
;;;;;;;;;;;;;;

(define P1-SCORE-0 0)
(define P2-SCORE-0 0)
(define HIGH-SCORE-0 0)
(define CREDIT-COUNT-0 15)
(define SECOND-COUNT-0 0)
(define CTRL-PANEL-0 (make-ctrl-panel #true 0 "cavity" #false #false))
(define MODE-0 (make-attract 1 "cavity"))

; seconds per clock tick
(define SPT 1/30)
; whether to debug or not
(define DEBUG? #false)
; scale factor for entire canvas
(define SCALE-FACTOR 3)

; character block side length in pixels
(define CHAR-BLK-LENGTH 8)

; number of columns in playfield
(define PF-COL-COUNT 28)
; number of rows in playfield
(define PF-ROW-COUNT 32)

; background color
(define BG-COLOR "black")
; foreground colors
(define FG-COLORS
  (list (make-color-overlay "blue"   0 5)
        (make-color-overlay "orange" 5 9)
        (make-color-overlay "green"  9 13)
        (make-color-overlay "yellow" 13 29)
        (make-color-overlay "blue"   29 30)
        (make-color-overlay "white"  30 PF-ROW-COUNT)))

; playfield spacing in pixels
(define PF-SPACING (/ CHAR-BLK-LENGTH 4))

; ball radius in pixels
(define BALL-RADIUS (* PF-SPACING 3/4))

;;; Derived constants

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

; ball minimum position on the x-coordinate
(define BALL-MIN-X (+ WALL-THICKNESS (/ PF-SPACING 2) BALL-RADIUS))
; ball maximum position on the x-coordinate
(define BALL-MAX-X (- PF-WIDTH BALL-MIN-X))
; ball minimum position on the y-coordinate
(define BALL-MIN-Y (- BRICK-HEIGHT (/ IBRICK-HEIGHT 2)))
; ball maximum position on the y-coordinate
(define BALL-MAX-Y (- PF-HEIGHT CHAR-BLK-LENGTH BALL-RADIUS))

;;; Data examples
;;;;;;;;;;;;;;;;;;

; Backwall
(define BACKWALL (make-backwall))

;;; Images
;;;;;;;;;;;

; overlay image
(define OVERLAY-IMG
  (freeze
   (apply
    above
    (map (lambda (a-color-overlay)
           (local ((define a-c (color-overlay-c a-color-overlay))
                   (define a-i (color-overlay-i a-color-overlay))
                   (define a-j (color-overlay-j a-color-overlay)))
             (rectangle PF-WIDTH
                        (* (- a-j a-i) BRICK-HEIGHT)
                        "solid" a-c)))
         FG-COLORS))))

; playfield image
(define PF-IMG
  (freeze
   (overlay/align
    "center" "bottom"
    (rectangle (- PF-WIDTH PF-SPACING (* 2 WALL-THICKNESS))
               (- PF-HEIGHT WALL-THICKNESS (/ PF-SPACING 2))
               "solid" BG-COLOR)
    (crop/align "center" "bottom"
                (- PF-WIDTH PF-SPACING)
                (- PF-HEIGHT (/ PF-SPACING 2))
                OVERLAY-IMG)
    (rectangle PF-WIDTH PF-HEIGHT "solid" BG-COLOR))))

;;; Font functions

; byte-list->bitmap : List<Byte> -> Image
; convert a list of Bytes to a bitmap
(define (byte-list->bitmap lob)
  (color-list->bitmap
   (map (lambda (bit) (if (string=? bit "1") "white" "black"))
        (explode (apply string-append lob)))
   8 8))

; name of CSV file containing a 8x8 monochrome bitmap font
(define FONT-FILENAME "Super_Breakout_Font_8x8.csv")
; list of character bitmaps
(define CHAR-BITMAPS
  (list->vector (read-csv-file/rows FONT-FILENAME byte-list->bitmap)))

; string->bitmap : String -> Image
; convert a string to a bitmap
(define (string->bitmap str)
  (1string-list->bitmap
   (explode
    (string-upcase str))))

; 1string-list->bitmap : List<String> -> Image
; convert a list of 1-letter strings to a bitmap
(define (1string-list->bitmap strs)
  (cond
    [(empty? strs) empty-image]
    [(empty? (rest strs)) (1string->bitmap (first strs))]
    [else
     (beside (1string->bitmap (first strs))
             (1string-list->bitmap (rest strs)))]))

; 1string->bitmap : String -> Image
; convert a 1-letter string to a bitmap
(define (1string->bitmap str)
  (vector-ref CHAR-BITMAPS (string->int str)))

;;; Auxiliary functions
;;;;;;;;;;;;;;;;;;;;;;;;

; get-first : [X -> Boolean] List<X> -> Maybe<X>
; get the first element of list 'l' that satisfies predicate 'p?', if it exists;
; otherwise, return #false
(define (get-first p? l)
  (cond
    [(empty? l) #false]
    [else
     (local ((define first-l (first l)))
       (if (p? first-l)
           first-l
           (get-first p? (rest l))))]))

; row->color : NonnegativeInteger -> Color
; convert row number 'row' into a Color
(define (row->color row)
  (color-overlay-c
   (get-first
    (lambda (a-color-overlay)
      (and (<= (color-overlay-i a-color-overlay) row)
           (< row (color-overlay-j a-color-overlay))))
    FG-COLORS)))

; row->y : NonnegativeInteger -> Number
; convert row number 'row' into a position in the y-coordinate
(define (row->y row)
  (* row CHAR-BLK-LENGTH))

; col->x : NonnegativeInteger -> Number
; convert column number 'col' into a position in the x-coordinate
(define (col->x col)
  (* col CHAR-BLK-LENGTH))

; brick-collision-geometry : Brick -> CollisionGeometry
; get the collision geometry of Brick 'a-brick'
(define (brick-collision-geometry a-brick)
  (local ((define x (col->x (brick-col a-brick)))
          (define y (row->y (brick-row a-brick)))
          (define a-top (- y (/ IBRICK-HEIGHT 2))))
    (make-collision-geometry x a-top
                             (+ x BRICK-WIDTH)
                             (+ a-top BRICK-HEIGHT))))

; paddle-collision-geometry : Paddle -> CollisionGeometry
; get the collision geometry of Paddle 'a-paddle'
(define (paddle-collision-geometry a-paddle)
  (local ((define x (paddle-x a-paddle))
          (define y (row->y (paddle-row a-paddle)))
          (define a-top (- y (/ (+ IBRICK-HEIGHT PF-SPACING) 2))))
    (make-collision-geometry (- x (/ PF-SPACING 2))
                             a-top
                             (+ x (paddle-width a-paddle) (/ PF-SPACING 2))
                             (+ y (- BRICK-HEIGHT (* PF-SPACING 3/2))))))

; ball-vx : Ball -> Number
; get the velocity in the x-direction of 'a-ball'
(define (ball-vx a-ball)
  (* (cos (ball-dir a-ball))
     (ball-speed a-ball)
     SPT))

; ball-vy : Ball -> Number
; get the velocity in the y-direction of 'a-ball'
(define (ball-vy a-ball)
  (* (sin (ball-dir a-ball))
     (ball-speed a-ball)
     SPT))

; reflect-h : Angle -> Angle
; reflect Angle 'a' horizontally
(define (reflect-h a)
  (* (sgn a) (- pi (abs a))))

; reflect-v : Angle -> Angle
; reflect Angle 'a' vertically
(define (reflect-v a)
  (- a))

; get-dir : Number Paddle -> Angle
; get an angle of reflection of a point with horizontal position 'x'
; given that it collided with Paddle 'a-paddle'
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

; update-bricks : List<Ball> List<Brick> -> List<Brick>
; remove Bricks from a list of Bricks 'a-lobr' given a list of Balls 'a-loba'
(define (update-bricks a-loba a-lobr)
  (cond
    [(empty? a-loba) a-lobr]
    [else
     (local (; first
             (define first-ball (first a-loba))
             ; rest
             (define rest-loba (rest a-loba)))
       (if (positive? (ball-tick-score first-ball))
           (remove (ball-last-vobject first-ball)
                   (update-bricks rest-loba a-lobr))
           (update-bricks rest-loba a-lobr)))]))

; update-score : List<Ball> NonnegativeInteger -> NonnegativeInteger
(define (update-score a-loba a-score)
  (+ a-score
     (apply + (map (lambda (a-ball)
                     (ball-tick-score a-ball))
                   a-loba))))

; brick-point-value : Brick -> NonnegativeInteger
(define (brick-point-value a-brick)
  1)

;;; Tick handling
;;;;;;;;;;;;;;;;;;

; update : Breakout -> Breakout
; update Breakout 'a-brkt' for one clock tick
(define (update a-brkt)
  (local (; current Balls in 'a-brkt'
          (define a-loba (breakout-loba a-brkt))
          ; current Mode in 'a-brkt'
          (define a-mode (breakout-mode a-brkt))
          ; updated Balls after one tick with 'a-brkt'
          (define new-loba
            (map (lambda (a-ball)
                   (update-ball a-ball a-brkt))
                 a-loba)))
    (cond
      [(attract? a-mode)
       (update-attract new-loba a-brkt)]
      [(ready-to-play? a-mode)
       (update-ready-to-play new-loba a-brkt)]
      [(play? a-mode)
       (process-balls new-loba a-brkt)])))

;;;;;;;;;;;;
;;; ATTRACT
;;;;;;;;;;;;

; update-attract : List<Ball> Breakout -> Breakout
; update Breakout 'a-brkt' in attract mode given
;    a new list of Balls 'new-loba' for one clock tick
(define (update-attract new-loba a-brkt)
  (local (; current Bricks in 'a-brkt'
          (define a-lobr (breakout-lobr a-brkt))
          ; total paddle hit count of all the new balls
          (define total-paddle-hit-count
            (apply + (map (lambda (a-ball)
                            (ball-paddle-hit-count a-ball))
                          new-loba))))
    (cond
      [(>= total-paddle-hit-count 50)
       (switch-attract a-brkt)]
      [else
       (process-balls new-loba a-brkt)])))

; switch-attract : Breakout -> Breakout
(define (switch-attract a-brkt)
  (local (; current Mode in 'a-brkt'
          (define a-mode (breakout-mode a-brkt))
          ; current Game in attract mode
          (define a-game (attract-game a-mode)))
    (cond
      [(= 2 (attract-version a-mode))
       ATTRACT-CAVITY-0]
      [(string=? a-game "cavity")
       ATTRACT-DOUBLE-0]
      [(string=? a-game "double")
       ATTRACT-PROGRESSIVE-0]
      [(string=? a-game "progressive")
       ATTRACT-CAVITY-0])))

; process-balls : List<Ball> Breakout -> Breakout
(define (process-balls new-loba a-brkt)
  (local (; current Bricks in 'a-brkt'
          (define a-lobr (breakout-lobr a-brkt))
          ; attract mode version
          (define version (attract-version (breakout-mode a-brkt)))
          ; current p1-score in 'a-brkt'
          (define a-p1-score (breakout-p1-score a-brkt)))
    (make-breakout new-loba
                   (if (= 1 version)
                       (update-bricks new-loba a-lobr)
                       a-lobr)
                   (breakout-lop a-brkt)
                   (update-score new-loba a-p1-score)
                   (breakout-p2-score a-brkt)
                   (breakout-high-score a-brkt)
                   (breakout-credit-count a-brkt)
                   (+ SPT (breakout-second-count a-brkt))
                   (breakout-ctrl-panel a-brkt)
                   (breakout-mode a-brkt))))

;;;;;;;;;;;;;;;;;;
;;; READY-TO-PLAY
;;;;;;;;;;;;;;;;;;

; update-ready-to-play : List<Ball> Breakout -> Breakout
; update Breakout 'a-brkt' in ready-to-play mode given
;    a new list of Balls 'new-loba' for one clock tick
(define (update-ready-to-play new-loba a-brkt)
  (local (; current Control Panel in 'a-brkt'
          (define a-ctrl-panel (breakout-ctrl-panel a-brkt))
          ; current selected Game in 'a-brkt'
          (define a-game (ctrl-panel-game a-ctrl-panel)))
    (cond
      [(string=? a-game "cavity")
       READY-TO-PLAY-CAVITY-0]
      [(string=? a-game "double")
       READY-TO-PLAY-DOUBLE-0]
      [(string=? a-game "progressive")
       READY-TO-PLAY-PROGRESSIVE-0])))

;;;;;;;;;
;;; PLAY
;;;;;;;;;

;(define (update-play a-brkt)
;  (cond
;    [(cavity? (play-game a))
;     (update-play-cavity a-brkt)]
;    [(double? (play-game a))
;     (update-play-double a-brkt)]
;    [(progressive? (play-game a))
;     (update-play-progressive a-brkt)]))

;;;;;;;;;;;;;;;;;;
;;; BALL HANDLING
;;;;;;;;;;;;;;;;;;

; update-ball : Ball Breakout -> Ball
; update 'a-ball' for one clock tick given current Breakout 'a-brkt'
(define (update-ball a-ball a-brkt)
  (local (; ball serve delay
          (define serve-delay (ball-serve-delay a-ball)))
    (cond
      [(positive? serve-delay)
       (make-ball (ball-x a-ball)
                  (ball-y a-ball)
                  (ball-speed a-ball)
                  (ball-dir a-ball)
                  (ball-last-vobject a-ball)
                  (ball-tick-score a-ball)
                  (ball-paddle-hit-count a-ball)
                  (- serve-delay SPT)
                  (ball-visible? a-ball))]
      [else
       (local (; current Blocks in 'a-brkt'
               (define a-lobr (breakout-lobr a-brkt))
               ; current Paddles in 'a-brkt'
               (define a-lop (breakout-lop a-brkt))
               ; 'a-ball' initial position
               (define x1 (ball-x a-ball))
               (define y1 (ball-y a-ball))
               ; 'a-ball' final position without collisions
               (define x2 (+ x1 (ball-vx a-ball)))
               (define y2 (+ y1 (ball-vy a-ball)))
               ; updated 'a-ball' considering 'BALL-MIN-X' and 'BALL-MAX-X'
               (define new-ball
                 (cond
                   ; right sidewall collision
                   [(>= x2 BALL-MAX-X)
                    (make-ball BALL-MAX-X y2
                               (ball-speed a-ball)
                               (reflect-h (ball-dir a-ball))
                               (ball-last-vobject a-ball)
                               0
                               (ball-paddle-hit-count a-ball)
                               serve-delay
                               #true)]
                   ; left sidewall collision
                   [(<= x2 BALL-MIN-X)
                    (make-ball BALL-MIN-X y2
                               (ball-speed a-ball)
                               (reflect-h (ball-dir a-ball))
                               (ball-last-vobject a-ball)
                               0
                               (ball-paddle-hit-count a-ball)
                               serve-delay
                               #true)]
                   ; no collision
                   [else
                    (make-ball x2 y2
                               (ball-speed a-ball)
                               (ball-dir a-ball)
                               (ball-last-vobject a-ball)
                               0
                               (ball-paddle-hit-count a-ball)
                               serve-delay
                               #true)]))
               ; 'new-ball' position
               (define x3 (ball-x new-ball))
               (define y3 (ball-y new-ball))
               ; brick-collision? : Brick -> Boolean
               ; check whether 'new-ball' is in collision with 'a-brick'
               (define (brick-collision? a-brick)
                 (local ((define a-collision-geometry (brick-collision-geometry a-brick))
                         (define left (collision-geometry-left a-collision-geometry))
                         (define top (collision-geometry-top a-collision-geometry))
                         (define right (collision-geometry-right a-collision-geometry))
                         (define bottom (collision-geometry-bottom a-collision-geometry))
                         (define last-vobject (ball-last-vobject new-ball)))
                   (and (<= left x3 right)
                        (<= top y3 bottom)
                        (or (and (backwall? last-vobject)
                                 (< 1 (brick-row a-brick)))
                            (and (paddle? last-vobject)
                                 (< 1 (abs (- (paddle-row last-vobject)
                                              (brick-row a-brick)))))
                            (and (brick? last-vobject)
                                 (< 3 (abs (- (brick-row last-vobject)
                                              (brick-row a-brick)))))))))
               ; paddle-collision? : Paddle -> Boolean
               ; check whether 'new-ball' is in collision with 'a-paddle'
               (define (paddle-collision? a-paddle)
                 (local ((define a-collision-geometry (paddle-collision-geometry a-paddle))
                         (define left (collision-geometry-left a-collision-geometry))
                         (define top (collision-geometry-top a-collision-geometry))
                         (define right (collision-geometry-right a-collision-geometry))
                         (define bottom (collision-geometry-bottom a-collision-geometry)))
                   (and (<= left x3 right)
                        (<= top y3 bottom))))
               ; brick that collided with 'new-ball', if any
               (define collided-brick (get-first brick-collision? a-lobr))
               ; paddle that collided with 'new-ball', if any
               (define collided-paddle (get-first paddle-collision? a-lop)))
         (cond
           ; bottom of playfield collision
           [(> y3 BALL-MAX-Y)
            (make-ball x3 y3
                       (ball-speed new-ball)
                       (reflect-v (ball-dir new-ball))
                       (ball-last-vobject new-ball)
                       0
                       (ball-paddle-hit-count new-ball)
                       serve-delay
                       #true)]
           ; backwall collision
           [(< y3 BALL-MIN-Y)
            (make-ball x3 y3
                       (ball-speed new-ball)
                       (reflect-v (ball-dir new-ball))
                       BACKWALL
                       0
                       (ball-paddle-hit-count new-ball)
                       serve-delay
                       #true)]
           ; brick collision
           [(not (false? collided-brick))
            (make-ball x3 y3
                       (ball-speed new-ball)
                       (reflect-v (ball-dir new-ball))
                       collided-brick
                       (brick-point-value collided-brick)
                       (ball-paddle-hit-count new-ball)
                       serve-delay
                       #true)]
           ; paddle collision
           [(not (false? collided-paddle))
            (make-ball x3 y3
                       (ball-speed new-ball)
                       (get-dir x3 collided-paddle)
                       collided-paddle
                       0
                       (add1 (ball-paddle-hit-count new-ball))
                       serve-delay
                       #true)]
           ; no collision
           [else
            (make-ball x3 y3
                       (ball-speed new-ball)
                       (ball-dir new-ball)
                       (ball-last-vobject new-ball)
                       0
                       (ball-paddle-hit-count new-ball)
                       serve-delay
                       #true)]))])))

;;; Rendering
;;;;;;;;;;;;;;

; render : Breakout -> Breakout
; a rendered breakout game 'a-brkt'
(define (render a-brkt)
  (scale
   SCALE-FACTOR
   (render-balls (breakout-loba a-brkt)
                 (render-bricks (breakout-lobr a-brkt)
                                (render-paddles (breakout-lop a-brkt)
                                                (render-text PF-IMG))))))

; render-text : Image -> Image
(define (render-text bg-img)
  (place-image (string->bitmap "1 COIN  1 PLAYER")
               (+ (col->x 10)
                  (/ BRICK-WIDTH 2))
               (+ (row->y 30)
                  (/ BRICK-HEIGHT 2))
               bg-img))

; render-blocks : List<Block> Image -> Image
; a 'bg-img' with Bricks 'a-lobr' placed on it
(define (render-bricks a-lobr bg-img)
  (cond
    [(empty? a-lobr) bg-img]
    [else
     (local (; first Brick in 'a-lobr'
             (define a-brick (first a-lobr)))
       (place-image (freeze (+ (col->x (brick-col a-brick)) (/ PF-SPACING 2))
                            (+ (row->y (brick-row a-brick)) (/ PF-SPACING 2))
                            IBRICK-WIDTH
                            IBRICK-HEIGHT
                            OVERLAY-IMG)
                    (+ (col->x (brick-col a-brick))
                       (/ BRICK-WIDTH 2))
                    (+ (row->y (brick-row a-brick))
                       (/ BRICK-HEIGHT 2))
                    (render-bricks (rest a-lobr) bg-img)))]))

; render-balls : List<Ball> Image -> Image
; a 'bg-img' with Balls 'a-loba' placed on it
(define (render-balls a-loba bg-img)
  (cond
    [(empty? a-loba) bg-img]
    [else
     (local (; first Ball in 'a-loba'
             (define a-ball (first a-loba)))
       (place-image (freeze (- (ball-x a-ball) BALL-RADIUS)
                            (- (ball-y a-ball) BALL-RADIUS)
                            (* 2 BALL-RADIUS)
                            (* 2 BALL-RADIUS)
                            OVERLAY-IMG)
                    (ball-x a-ball)
                    (ball-y a-ball)
                    (render-balls (rest a-loba) bg-img)))]))

; render-paddles : List<Paddle> Image -> Image
; a 'bg-img' with Paddles 'a-lop' placed on it
(define (render-paddles a-lop bg-img)
  (cond
    [(empty? a-lop) bg-img]
    [else
     (local (; first Paddle in 'a-lop'
             (define a-paddle (first a-lop)))
       (place-image (freeze (+ (paddle-x a-paddle) (/ PF-SPACING 2))
                            (row->y (paddle-row a-paddle))
                            (- (paddle-width a-paddle) PF-SPACING)
                            IBRICK-HEIGHT
                            OVERLAY-IMG)
                    (+ (paddle-x a-paddle)
                       (/ (paddle-width a-paddle) 2))
                    (+ (row->y (paddle-row a-paddle))
                       (/ IBRICK-HEIGHT 2))
                    (render-paddles (rest a-lop) bg-img)))]))

;;; Key handling
;;;;;;;;;;;;;;;;;

; handle-key : Breakout KeyEvent -> Breakout
(define (handle-key a-brkt key)
  (cond
    [(key=? " " key)
     (try-serve a-brkt)]
    [(key=? "\r" key)
     (try-insert-coin a-brkt)]
    [(or (key=? "left" key)
         (key=? "up" key)
         (key=? "a" key)
         (key=? "w" key))
     (try-switch-left-game a-brkt)]
    [(or (key=? "right" key)
         (key=? "bottom" key)
         (key=? "d" key)
         (key=? "s" key))
     (try-switch-right-game a-brkt)]
    [(key=? "1" key)
     (one-player a-brkt)]
    [(key=? "2" key)
     (two-player a-brkt)]))

; handle-mouse : Breakout Number Number MouseEvent -> Breakout
(define (handle-mouse a-brkt x y mouse)
  (try-update-paddles x a-brkt))

;;; Main function
;;;;;;;;;;;;;;;;;;

; run : Breakout -> Breakout
; run the breakout game with initial state 'a-brkt0'
(define (run a-brkt0)
  (big-bang a-brkt0
    [on-tick update SPT]
    [state DEBUG?]
    [to-draw render]))


(define ATTRACT-PADDLES-0
  (build-list (/ (- PF-COL-COUNT 2) 2)
              (lambda (n) (make-paddle (col->x (+ (* 2 n) 1)) 29 0 0 BRICK-WIDTH))))
; List<Block>
(define LOBR-0 (append (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 1)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 2)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 3)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 4)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 9)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 10)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 11)))
                       (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 12)))))
(define PROGRESSIVE-BRICKS-0
  (append (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 1)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 2)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 3)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 4)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 9)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 10)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 11)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 12)))))
(define DOUBLE-BRICKS-0
  (append (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 5)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 6)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 7)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 8)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 9)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 10)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 11)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 12)))))
(define CAVITY-BRICKS-0
  (append (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 5)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 6)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 7)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 8)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 9)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 10)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 11)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 12)))))
; List<Ball>
(define LOBA-0 (list (make-ball (* PF-WIDTH 1/6) (row->y 22) 500 (/ pi 4) BACKWALL 0 0 0 #true)))
; Breakout
(define BREAKOUT-0
  (make-breakout '()
                 LOBR-0
                 ATTRACT-PADDLES-0
                 P1-SCORE-0
                 P2-SCORE-0
                 HIGH-SCORE-0
                 CREDIT-COUNT-0
                 SECOND-COUNT-0
                 CTRL-PANEL-0
                 MODE-0))

;;; ATTRACT

(define ATTRACT-CAVITY-0
  (make-breakout (list (make-ball (* PF-WIDTH 1/6) (row->y 22) 400 (/ pi 4) BACKWALL 0 0 1 #false))
                 CAVITY-BRICKS-0
                 ATTRACT-PADDLES-0
                 P1-SCORE-0
                 P2-SCORE-0
                 HIGH-SCORE-0
                 CREDIT-COUNT-0
                 SECOND-COUNT-0
                 CTRL-PANEL-0
                 (make-attract 1 "cavity")))
(define ATTRACT-DOUBLE-0
  (make-breakout (list (make-ball (* PF-WIDTH 1/6) (row->y 22) 400 (/ pi 4) BACKWALL 0 0 1 #false)
                       (make-ball (* PF-WIDTH 2/6) (row->y 22) 400 (/ pi 4) BACKWALL 0 0 1.5 #false))
                 DOUBLE-BRICKS-0
                 ATTRACT-PADDLES-0
                 P1-SCORE-0
                 P2-SCORE-0
                 HIGH-SCORE-0
                 CREDIT-COUNT-0
                 SECOND-COUNT-0
                 CTRL-PANEL-0
                 (make-attract 1 "double")))
(define ATTRACT-PROGRESSIVE-0
  (make-breakout (list (make-ball (* PF-WIDTH 1/6) (row->y 22) 400 (/ pi 4) BACKWALL 0 0 1 #false))
                 PROGRESSIVE-BRICKS-0
                 ATTRACT-PADDLES-0
                 P1-SCORE-0
                 P2-SCORE-0
                 HIGH-SCORE-0
                 CREDIT-COUNT-0
                 SECOND-COUNT-0
                 CTRL-PANEL-0
                 (make-attract 1 "progressive")))

;;; READY-TO-PLAY

(define READY-TO-PLAY-CAVITY-0
  (make-breakout '()
                 CAVITY-BRICKS-0
                 (list (make-paddle (col->x 5) 29 0 0 BRICK-WIDTH))
                 P1-SCORE-0
                 P2-SCORE-0
                 HIGH-SCORE-0
                 CREDIT-COUNT-0
                 SECOND-COUNT-0
                 CTRL-PANEL-0
                 (make-ready-to-play)))
(define READY-TO-PLAY-DOUBLE-0
  (make-breakout '()
                 DOUBLE-BRICKS-0
                 (list (make-paddle (col->x 5) 26 0 0 BRICK-WIDTH)
                       (make-paddle (col->x 5) 29 0 0 BRICK-WIDTH))
                 P1-SCORE-0
                 P2-SCORE-0
                 HIGH-SCORE-0
                 CREDIT-COUNT-0
                 SECOND-COUNT-0
                 CTRL-PANEL-0
                 (make-ready-to-play)))
(define READY-TO-PLAY-PROGRESSIVE-0
  (make-breakout '()
                 PROGRESSIVE-BRICKS-0
                 (list (make-paddle (col->x 5) 29 0 0 BRICK-WIDTH))
                 P1-SCORE-0
                 P2-SCORE-0
                 HIGH-SCORE-0
                 CREDIT-COUNT-0
                 SECOND-COUNT-0
                 CTRL-PANEL-0
                 (make-ready-to-play)))

(run READY-TO-PLAY-PROGRESSIVE-0)
