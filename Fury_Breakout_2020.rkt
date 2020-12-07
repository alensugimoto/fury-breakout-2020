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
; a library for making sounds
(require rsound)

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
(define-struct paddle [x row width])

; a Backwall is (make-backwall)
; interpretation: a wall stretched over row number 0
(define-struct backwall [])
(define-struct frontwall [])
(define-struct none [])

(define NONE (make-none))

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
(define-struct ball [x y speed dir last-vobject tick-vobject paddle-hit-count serve-delay has-child?])

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
(define-struct play-mode [game has-one-serve? end-serve?])

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
(define-struct ctrl-panel [player-count paddle-posn game])

(define-struct high-scores [cavity double progressive])
(define-struct player [score loba lobr])

; a Breakout is (make-breakout loba lobr lop score high-score credit-count ctrl-panel mode)
;    where loba         : List<Ball>
;          lobr         : List<Brick>
;          lop          : List<Paddle>
;          score        : NonnegativeInteger
;          high-score   : NonnegativeInteger
;          credit-count : NonnegativeInteger
;          ctrl-panel   : ControlPanel
;          mode         : Mode
; interpretation: Super Breakout with Balls 'loba',
;                 Bricks 'lobr', Paddles 'lop', and
;                 current Mode of operation 'mode'
(define-struct breakout
  [loba lop serve-num p1? p1 p2 high-scores credit-count ctrl-panel mode next-silent-frame])

;;; Constants
;;;;;;;;;;;;;;

; seconds per clock tick
(define SPT 1/30)
; whether to debug or not
(define DEBUG? #false)
; scale factor for entire canvas
(define SCALE-FACTOR 3)

; character block side length in pixels
(define CHAR-BLK-LENGTH (* 8 SCALE-FACTOR))

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

; ball speed on serve
(define BALL-SPEED-0 400)
(define BALL-SPEED-MAX 600)
(define CAVITY-BALL-SPEED 300)

; normal paddle width
(define PADDLE-WIDTH-0 BRICK-WIDTH)
; halved paddle width
(define PADDLE-WIDTH-1 (* 5/8 PADDLE-WIDTH-0))

;;; Data examples
;;;;;;;;;;;;;;;;;;

; Backwall
(define BACKWALL (make-backwall))
(define FRONTWALL (make-frontwall))

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

(define (set-angle-60 a)
  (if (< 0 (abs a) (/ pi 2))
      (* (sgn a) pi 1/3)
      (* (sgn a) pi 2/3)))
  
; get-dir : Number Paddle -> Angle
; get an angle of reflection of a point with horizontal position 'x'
; given that it collided with Paddle 'a-paddle'
(define (get-dir x paddle-hit-count ball-speed a-paddle)
  (local ((define a-collision-geometry (paddle-collision-geometry a-paddle))
          (define left (collision-geometry-left a-collision-geometry))
          (define right (collision-geometry-right a-collision-geometry))
          (define width (- right left)))
    (cond
      [(and (<= (+ left (* width 0/4)) x) (< x (+ left (* width 1/4))))
       (if (= BALL-SPEED-MAX ball-speed)
           (* pi -2/3)
           (cond
             [(<= paddle-hit-count 3)
              (* pi -7/9)]
             [(<= 4 paddle-hit-count 7)
              (* pi -2/3)]
             [(<= 8 paddle-hit-count 11)
              (* pi -31/36)]
             [(<= 12 paddle-hit-count)
              (* pi -7/9)]))]
      [(and (<= (+ left (* width 1/4)) x) (<= x (+ left (* width 2/4))))
       (if (= BALL-SPEED-MAX ball-speed)
           (* pi -2/3)
           (cond
             [(<= paddle-hit-count 3)
              (* pi -2/3)]
             [(<= 4 paddle-hit-count 7)
              (* pi -2/3)]
             [(<= 8 paddle-hit-count 11)
              (* pi -31/36)]
             [(<= 12 paddle-hit-count)
              (* pi -7/9)]))]
      [(and (< (+ left (* width 2/4)) x) (<= x (+ left (* width 3/4))))
       (if (= BALL-SPEED-MAX ball-speed)
           (* pi -1/3)
           (cond
             [(<= paddle-hit-count 3)
              (* pi -1/3)]
             [(<= 4 paddle-hit-count 7)
              (* pi -1/3)]
             [(<= 8 paddle-hit-count 11)
              (* pi -5/36)]
             [(<= 12 paddle-hit-count)
              (* pi -2/9)]))]
      [(and (< (+ left (* width 3/4)) x) (<= x (+ left (* width 4/4))))
       (if (= BALL-SPEED-MAX ball-speed)
           (* pi -1/3)
           (cond
             [(<= paddle-hit-count 3)
              (* pi -2/9)]
             [(<= 4 paddle-hit-count 7)
              (* pi -1/3)]
             [(<= 8 paddle-hit-count 11)
              (* pi -5/36)]
             [(<= 12 paddle-hit-count)
              (* pi -2/9)]))])))

; brick-point-value : Brick -> NonnegativeInteger
(define (brick-point-value brick-row ball-count a-game)
  (cond
    [(or (string=? a-game "double")
         (string=? a-game "cavity"))
     (* ball-count
        ; play brick sound here
        (cond
          [(<= 5 brick-row 6) 7]
          [(<= 7 brick-row 8) 5]
          [(<= 9 brick-row 10) 3]
          [(<= 11 brick-row 12) 1]))]
    [(string=? a-game "progressive")
     (* ball-count
        (cond
          [(<= 1 brick-row 4) 7]
          [(<= 5 brick-row 8) 5]
          [(<= 9 brick-row 12) 3]
          [(<= 13 brick-row 28) 1]))]))

(define ANGLES (vector (* pi 1/4) (* pi 1/3) (* pi 2/3) (* pi 3/4)))

; serve-ball : NonnegativeInteger Breakout -> Breakout
; serve one random ball in 'a-brkt'
(define (serve-ball serve-delay has-child? a-brkt)
  (local ((define new-ball
            (make-ball (+ BALL-MIN-X (random (- BALL-MAX-X BALL-MIN-X -1)))
                       (/ PF-HEIGHT 2)
                       BALL-SPEED-0
                       (vector-ref ANGLES (random 4))
                       NONE
                       0 0 serve-delay has-child?)))
  (make-breakout (cons new-ball (breakout-loba a-brkt))
                 (breakout-lop a-brkt)
                 (breakout-serve-num a-brkt)
                 (breakout-p1? a-brkt)
                 (breakout-p1 a-brkt)
                 (breakout-p2 a-brkt)
                 (breakout-high-scores a-brkt)
                 (breakout-credit-count a-brkt)
                 (breakout-ctrl-panel a-brkt)
                 (if (play-mode? (breakout-mode a-brkt))
                     (make-play-mode (play-mode-game (breakout-mode a-brkt))
                                     #true
                                     #false)
                     (breakout-mode a-brkt))
                 (breakout-next-silent-frame a-brkt))))

;;; Font functions

; byte-list->bitmap : List<Byte> -> Image
; convert a list of Bytes to a bitmap
(define (byte-list->bitmap color lob)
  (scale
   SCALE-FACTOR
   (color-list->bitmap
    (map (lambda (bit) (if (string=? bit "1") color "black"))
         (explode (apply string-append lob)))
    8 8)))

; name of CSV file containing a 8x8 monochrome bitmap font
(define FONT-FILENAME "resources/font/Super_Breakout_Font_8x8.csv")
; list of character bitmaps
(define CHAR-BITMAPS
  (build-vector PF-ROW-COUNT
                (lambda (i)
                  (list->vector
                   (read-csv-file/rows FONT-FILENAME
                                       (lambda (lob)
                                         (byte-list->bitmap (row->color i) lob)))))))

; string->bitmap : String -> Image
; convert a string to a bitmap
(define (string->bitmap row str)
  (1string-list->bitmap
   row
   (explode
    (string-upcase str))))

; 1string-list->bitmap : List<String> -> Image
; convert a list of 1-letter strings to a bitmap
(define (1string-list->bitmap row strs)
  (cond
    [(empty? (rest strs))
     (1string->bitmap row (first strs))]
    [else
     (beside (1string->bitmap row (first strs))
             (1string-list->bitmap row (rest strs)))]))

; 1string->bitmap : String -> Image
; convert a 1-letter string to a bitmap
(define (1string->bitmap row str)
  (vector-ref (vector-ref CHAR-BITMAPS row) (string->int str)))

;;; Tick handling
;;;;;;;;;;;;;;;;;;

; update : Breakout -> Breakout
; update Breakout 'a-brkt' for one clock tick
(define (update a-brkt0)
  (local (; updated breakout
          (define a-brkt (update-balls a-brkt0))
          ; current Mode in 'a-brkt'
          (define a-mode (breakout-mode a-brkt)))
    (cond
      [(attract? a-mode)
       (update-attract a-brkt)]
      [(ready-to-play? a-mode)
       (update-ready-to-play a-brkt)]
      [(play-mode? a-mode)
       (update-play a-brkt)])))

; update-balls : Breakout -> Breakout
(define (update-balls a-brkt)
  (if (andmap (lambda (a-ball)
                (positive? (ball-serve-delay a-ball)))
              (breakout-loba a-brkt))
      (make-breakout (map (lambda (a-ball)
                            (if (positive? (ball-serve-delay a-ball))
                                (make-ball (ball-x a-ball)
                                           (ball-y a-ball)
                                           (ball-speed a-ball)
                                           (ball-dir a-ball)
                                           (ball-last-vobject a-ball)
                                           (ball-tick-vobject a-ball)
                                           (ball-paddle-hit-count a-ball)
                                           (- (ball-serve-delay a-ball) SPT)
                                           (ball-has-child? a-ball))
                                a-ball))
                          (breakout-loba a-brkt))
                     (breakout-lop a-brkt)
                     (breakout-serve-num a-brkt)
                     (breakout-p1? a-brkt)
                     (breakout-p1 a-brkt)
                     (breakout-p2 a-brkt)
                     (breakout-high-scores a-brkt)
                     (breakout-credit-count a-brkt)
                     (breakout-ctrl-panel a-brkt)
                     (breakout-mode a-brkt)
                     (breakout-next-silent-frame a-brkt))
      (local (; balls before filtering invalid ones
              (define a-loba0
                (map (lambda (a-ball)
                       (update-ball a-ball #true a-brkt))
                     (breakout-loba a-brkt)))
              ; balls after filtering invalid ones
              (define a-loba
                (filter (lambda (a-ball)
                          (not (frontwall? (ball-tick-vobject a-ball))))
                        a-loba0))
              ; players
              (define a-p1 (breakout-p1 a-brkt))
              (define a-p2 (breakout-p2 a-brkt))
              ; update player balls
              (define player-balls
                (if (breakout-p1? a-brkt)
                    (map (lambda (a-ball)
                            (update-ball a-ball #false a-brkt))
                          (player-loba a-p1))
                    (map (lambda (a-ball)
                            (update-ball a-ball #false a-brkt))
                          (player-loba a-p2))))
              ; append player balls
              (define new-loba
                (append (filter (lambda (a-ball)
                                  (or (backwall? (ball-tick-vobject a-ball))
                                      (paddle? (ball-tick-vobject a-ball))))
                                player-balls)
                        a-loba))
              ; remove appended balls
              (define new-player-balls
                (filter (lambda (a-ball)
                          (not (or (backwall? (ball-tick-vobject a-ball))
                                   (paddle? (ball-tick-vobject a-ball)))))
                        player-balls))
              ; end of serve?
              (define end-serve? (empty? new-loba)))
        (foldr (lambda (a-ball some-brkt)
                 (if (and (ball-has-child? a-ball)
                          (= 1 (ball-paddle-hit-count a-ball))
                          (paddle? (ball-tick-vobject a-ball)))
                     (serve-ball 0 #false some-brkt)
                     some-brkt))
               (make-breakout new-loba
                              (if (and (not (attract? (breakout-mode a-brkt)))
                                       (ormap (lambda (a-ball)
                                                (backwall? (ball-tick-vobject a-ball)))
                                              new-loba))
                                  (map (lambda (a-paddle)
                                         (make-paddle (paddle-x a-paddle)
                                                      (paddle-row a-paddle)
                                                      PADDLE-WIDTH-1))
                                       (breakout-lop a-brkt))
                                  (breakout-lop a-brkt))
                              (breakout-serve-num a-brkt)
                              (breakout-p1? a-brkt)
                              (if (breakout-p1? a-brkt)
                                  (make-player (player-score a-p1)
                                               new-player-balls
                                               (player-lobr a-p1))
                                  a-p1)
                              (if (breakout-p1? a-brkt)
                                  a-p2
                                  (make-player (player-score a-p2)
                                               new-player-balls
                                               (player-lobr a-p2)))
                              (breakout-high-scores a-brkt)
                              (breakout-credit-count a-brkt)
                              (breakout-ctrl-panel a-brkt)
                              (if (play-mode? (breakout-mode a-brkt))
                                  (make-play-mode (play-mode-game (breakout-mode a-brkt))
                                                  (play-mode-has-one-serve? (breakout-mode a-brkt))
                                                  end-serve?)
                                  (breakout-mode a-brkt))
                              (if (and end-serve?
                                       (pstream? (pstream-set-volume! RS-TICK-STREAM 0))
                                       (void? (pstream-clear! RS-TICK-STREAM)))
                                  (andplay RS-BOOP
                                           (+ (rs-frames RS-BOOP)
                                              (pstream-current-frame RS-TICK-STREAM)))
                                  (breakout-next-silent-frame a-brkt)))
               new-loba))))

(define (handle-end-serve a-brkt)
  (make-breakout (breakout-loba a-brkt)
                 (if (and (play-mode-end-serve? (breakout-mode a-brkt))
                          (> (pstream-current-frame RS-TICK-STREAM)
                             (breakout-next-silent-frame a-brkt)))
                     (map (lambda (a-paddle)
                            (make-paddle (paddle-x a-paddle)
                                         (paddle-row a-paddle)
                                         PADDLE-WIDTH-0))
                          (breakout-lop a-brkt))
                     (breakout-lop a-brkt))
                 (if (and (play-mode-end-serve? (breakout-mode a-brkt))
                          (> (pstream-current-frame RS-TICK-STREAM)
                             (breakout-next-silent-frame a-brkt)))
                     (if (= 1 (ctrl-panel-player-count
                               (breakout-ctrl-panel a-brkt)))
                         (+ 1 (breakout-serve-num a-brkt))
                         (+ 0.5 (breakout-serve-num a-brkt)))
                     (breakout-serve-num a-brkt))
                 (if (and (play-mode-end-serve? (breakout-mode a-brkt))
                          (> (pstream-current-frame RS-TICK-STREAM)
                             (breakout-next-silent-frame a-brkt)))
                     (if (= 1 (ctrl-panel-player-count
                               (breakout-ctrl-panel a-brkt)))
                         #true
                         (not (breakout-p1? a-brkt)))
                     (breakout-p1? a-brkt))
                 (breakout-p1 a-brkt)
                 (breakout-p2 a-brkt)
                 (breakout-high-scores a-brkt)
                 (breakout-credit-count a-brkt)
                 (breakout-ctrl-panel a-brkt)
                 (if (and (play-mode-end-serve? (breakout-mode a-brkt))
                          (> (pstream-current-frame RS-TICK-STREAM)
                             (breakout-next-silent-frame a-brkt)))
                     (make-play-mode (play-mode-game (breakout-mode a-brkt))
                                     (play-mode-has-one-serve? (breakout-mode a-brkt))
                                     #false)
                     (breakout-mode a-brkt))
                 (breakout-next-silent-frame a-brkt)))

; update-ball : Ball Breakout -> Ball
; update 'a-ball' for one clock tick given current Breakout 'a-brkt'
(define (update-ball a-ball active? a-brkt)
  (local (; current Blocks in 'a-brkt'
          (define a-lobr
            (player-lobr (if (breakout-p1? a-brkt)
                             (breakout-p1 a-brkt)
                             (breakout-p2 a-brkt))))
          ; current Paddles in 'a-brkt'
          (define a-lop (breakout-lop a-brkt))
          ; current mode
          (define a-mode (breakout-mode a-brkt))
          ; updated 'a-ball' considering 'BALL-MIN-X' and 'BALL-MAX-X'
          (define new-ball
            (move a-ball (not (attract? a-mode))))
          ; try-andplay
          (define (try-andplay snd a-ball a-mode)
            (if (attract? a-mode)
                a-ball
                (andplay snd a-ball)))
          ; current game
          (define a-game
            (cond
              [(play-mode? a-mode)
               (play-mode-game a-mode)]
              [(attract? a-mode)
               (attract-game a-mode)]
              [else
               (ctrl-panel-game (breakout-ctrl-panel a-brkt))]))
          ; 'new-ball' position
          (define x3 (ball-x new-ball))
          (define y3 (ball-y new-ball))
          ; brick-collision? : Brick -> Boolean
          ; check whether 'new-ball' is in collision with 'a-brick'
          (define (brick-collision? b a-brick)
            (local ((define a-collision-geometry (brick-collision-geometry a-brick))
                    (define left (collision-geometry-left a-collision-geometry))
                    (define top (collision-geometry-top a-collision-geometry))
                    (define right (collision-geometry-right a-collision-geometry))
                    (define bottom (collision-geometry-bottom a-collision-geometry))
                    (define last-vobject (ball-last-vobject b)))
              (and (<= left (ball-x b) right)
                   (<= top (ball-y b) bottom)
                   (or (none? last-vobject)
                       (and (backwall? last-vobject)
                            (< 1 (brick-row a-brick)))
                       (and (paddle? last-vobject)
                            (< 1 (abs (- (paddle-row last-vobject)
                                         (brick-row a-brick)))))
                       (and (brick? last-vobject)
                            (< (if (string=? a-game "progressive")
                                   4 8)
                               (abs (- (brick-row last-vobject)
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
                   (<= top y3 bottom)
                   (positive? (ball-dir new-ball)))))
          ; brick that collided with 'new-ball', if any
          (define collided-brick (get-first (lambda (a-brick)
                                              (brick-collision? new-ball a-brick))
                                            a-lobr))
          ; paddle that collided with 'new-ball', if any
          (define collided-paddle (get-first paddle-collision? a-lop)))
    (cond
      ; bottom of playfield collision
      [(> y3 BALL-MAX-Y)
       (make-ball x3 y3
                  (ball-speed new-ball)
                  (reflect-v (ball-dir new-ball))
                  FRONTWALL
                  FRONTWALL
                  (ball-paddle-hit-count new-ball)
                  (ball-serve-delay new-ball)
                  (ball-has-child? new-ball))]
      ; backwall collision
      [(< y3 BALL-MIN-Y)
       (make-ball x3 y3
                  (max (ball-speed new-ball) BALL-SPEED-0)
                  (reflect-v (ball-dir new-ball))
                  BACKWALL
                  BACKWALL
                  (ball-paddle-hit-count new-ball)
                  (ball-serve-delay new-ball)
                  (ball-has-child? new-ball))]
      ; brick collision
      [(not (false? collided-brick))
       (if active?
           (make-ball x3 y3
                      (get-speed (ball-paddle-hit-count new-ball)
                                 collided-brick
                                 (ball-speed new-ball))
                      (if (highpoint-brick? collided-brick)
                          (set-angle-60 (reflect-v (ball-dir new-ball)))
                          (reflect-v (ball-dir new-ball)))
                      collided-brick
                      collided-brick
                      (ball-paddle-hit-count new-ball)
                      (ball-serve-delay new-ball)
                      (ball-has-child? new-ball))
           (if (ormap (lambda (a-brick)
                        (brick-collision? (move (set-reflect-h collided-brick new-ball) #false)
                                          a-brick))
                      a-lobr)
               (if (ormap (lambda (a-brick)
                            (brick-collision? (move (set-reflect-v collided-brick new-ball) #false)
                                              a-brick))
                          a-lobr)
                   (make-ball x3 y3
                              (ball-speed new-ball)
                              (reflect-v (reflect-h (ball-dir new-ball)))
                              (ball-last-vobject new-ball)
                              collided-brick
                              (ball-paddle-hit-count new-ball)
                              (ball-serve-delay new-ball)
                              (ball-has-child? new-ball))
                   (make-ball x3 y3
                              (ball-speed new-ball)
                              (reflect-v (ball-dir new-ball))
                              (ball-last-vobject new-ball)
                              collided-brick
                              (ball-paddle-hit-count new-ball)
                              (ball-serve-delay new-ball)
                              (ball-has-child? new-ball)))
               (make-ball x3 y3
                          (ball-speed new-ball)
                          (reflect-h (ball-dir new-ball))
                          (ball-last-vobject new-ball)
                          collided-brick
                          (ball-paddle-hit-count new-ball)
                          (ball-serve-delay new-ball)
                          (ball-has-child? new-ball))))]
      ; paddle collision
      [(not (false? collided-paddle))
       (try-andplay
        RS-BLIP
        (make-ball x3 y3
                   (get-speed (add1 (ball-paddle-hit-count new-ball))
                              collided-paddle
                              (ball-speed new-ball))
                   (get-dir x3
                            (add1 (ball-paddle-hit-count new-ball))
                            (get-speed (add1 (ball-paddle-hit-count new-ball))
                                       collided-paddle
                                       (ball-speed new-ball))
                            collided-paddle)
                   collided-paddle
                   collided-paddle
                   (add1 (ball-paddle-hit-count new-ball))
                   (ball-serve-delay new-ball)
                   (ball-has-child? new-ball))
        a-mode)]
      ; no collision
      [else
       (make-ball x3 y3
                  (ball-speed new-ball)
                  (ball-dir new-ball)
                  (ball-last-vobject new-ball)
                  NONE
                  (ball-paddle-hit-count new-ball)
                  (ball-serve-delay new-ball)
                  (ball-has-child? new-ball))])))

(define (get-speed paddle-hit-count vobject ball-speed)
  (max ball-speed
       (cond
         [(and (brick? vobject)
               (highpoint-brick? vobject))
          BALL-SPEED-MAX]
         [(paddle? vobject)
          (cond
            [(= 1 paddle-hit-count)
             (+ BALL-SPEED-0 (* (- BALL-SPEED-MAX BALL-SPEED-0) 0/4))]
            [(= 4 paddle-hit-count)
             (+ BALL-SPEED-0 (* (- BALL-SPEED-MAX BALL-SPEED-0) 1/4))]
            [(= 8 paddle-hit-count)
             (+ BALL-SPEED-0 (* (- BALL-SPEED-MAX BALL-SPEED-0) 2/4))]
            [(= 12 paddle-hit-count)
             (+ BALL-SPEED-0 (* (- BALL-SPEED-MAX BALL-SPEED-0) 3/4))]
            [else
             ball-speed])]
         [else
          ball-speed])))

(define (highpoint-brick? a-brick)
  (<= 1 (brick-row a-brick) 8))

(define (set-reflect-h tick-vobject a-ball)
  (make-ball (ball-x a-ball)
             (ball-y a-ball)
             (ball-speed a-ball)
             (reflect-h (ball-dir a-ball))
             (ball-last-vobject a-ball)
             tick-vobject
             (ball-paddle-hit-count a-ball)
             (ball-serve-delay a-ball)
             (ball-has-child? a-ball)))

(define (set-reflect-v tick-vobject a-ball)
  (make-ball (ball-x a-ball)
             (ball-y a-ball)
             (ball-speed a-ball)
             (reflect-v (ball-dir a-ball))
             (ball-last-vobject a-ball)
             tick-vobject
             (ball-paddle-hit-count a-ball)
             (ball-serve-delay a-ball)
             (ball-has-child? a-ball)))

(define (move a-ball sound?)
  (local ((define x2 (+ (ball-x a-ball) (ball-vx a-ball)))
          (define y2 (+ (ball-y a-ball) (ball-vy a-ball))))
    (cond
      ; right sidewall collision
      [(>= x2 BALL-MAX-X)
       (local ((define new-ball
                 (make-ball BALL-MAX-X y2
                            (ball-speed a-ball)
                            (reflect-h (ball-dir a-ball))
                            (ball-last-vobject a-ball)
                            NONE
                            (ball-paddle-hit-count a-ball)
                            (ball-serve-delay a-ball)
                            (ball-has-child? a-ball))))
         (if sound?
             (andplay RS-BOUNCE new-ball)
             new-ball))]
      ; left sidewall collision
      [(<= x2 BALL-MIN-X)
       (local ((define new-ball
                 (make-ball BALL-MIN-X y2
                            (ball-speed a-ball)
                            (reflect-h (ball-dir a-ball))
                            (ball-last-vobject a-ball)
                            NONE
                            (ball-paddle-hit-count a-ball)
                            (ball-serve-delay a-ball)
                            (ball-has-child? a-ball))))
         (if sound?
             (andplay RS-BOUNCE new-ball)
             new-ball))]
      ; no collision
      [else
       (make-ball x2 y2
                  (ball-speed a-ball)
                  (ball-dir a-ball)
                  (ball-last-vobject a-ball)
                  NONE
                  (ball-paddle-hit-count a-ball)
                  (ball-serve-delay a-ball)
                  (ball-has-child? a-ball))])))

;;;;;;;;;;;;
;;; ATTRACT
;;;;;;;;;;;;

; update-attract : Breakout -> Breakout
; update Breakout 'a-brkt' in attract mode given
;    a new list of Balls 'new-loba' for one clock tick
(define (update-attract a-brkt)
  (local ((define a-loba (breakout-loba a-brkt))
          ; total paddle hit count of all the new balls
          (define total-paddle-hit-count
            (apply + (map (lambda (a-ball)
                            (ball-paddle-hit-count a-ball))
                          a-loba)))
          ; current AttractVersion in attract mode
          (define a-version (attract-version (breakout-mode a-brkt))))
    (cond
      [(>= total-paddle-hit-count 1000)
       (switch-attract a-brkt)]
      [(= 1 a-version)
       (update-bricks a-brkt)]
      [else a-brkt])))

; switch-attract : Breakout -> Breakout
(define (switch-attract a-brkt)
  (local (; current Mode in 'a-brkt'
          (define a-attract (breakout-mode a-brkt))
          ; current Game in attract mode
          (define a-game (attract-game a-attract))
          ; current AttractVersion in attract mode
          (define a-version (attract-version a-attract)))
    (cond
      [(= 2 a-version)
       (set-attract 1 "cavity" (serve-ball 1 #false (reset-game CAVITY-BALLS-0 CAVITY-BRICKS-0 ATTRACT-PADDLES a-brkt)))]
      [(string=? a-game "cavity")
       (set-attract 1 "double" (serve-ball 1 #true (reset-game DOUBLE-BALLS-0 DOUBLE-BRICKS-0 ATTRACT-PADDLES a-brkt)))]
      [(string=? a-game "double")
       (set-attract 1 "progressive" (serve-ball 1 #false (reset-game PROGRESSIVE-BALLS-0 PROGRESSIVE-BRICKS-0 ATTRACT-PADDLES a-brkt)))]
      [(string=? a-game "progressive")
       (set-attract 1 "cavity" (serve-ball 1 #false (reset-game CAVITY-BALLS-0 CAVITY-BRICKS-0 ATTRACT-PADDLES a-brkt)))])))

; set-attract-version
(define (set-attract a-version a-game a-brkt)
  (make-breakout (breakout-loba a-brkt)
                 (breakout-lop a-brkt)
                 (breakout-serve-num a-brkt)
                 (breakout-p1? a-brkt)
                 (breakout-p1 a-brkt)
                 (breakout-p2 a-brkt)
                 (breakout-high-scores a-brkt)
                 (breakout-credit-count a-brkt)
                 (breakout-ctrl-panel a-brkt)
                 (make-attract a-version a-game)
                 (breakout-next-silent-frame a-brkt)))

;;;;;;;;;;;;;;;;;;
;;; READY-TO-PLAY
;;;;;;;;;;;;;;;;;;

; update-ready-to-play : Breakout -> Breakout
; update Breakout 'a-brkt' in ready-to-play mode given
;    a new list of Balls 'new-loba' for one clock tick
(define (update-ready-to-play a-brkt)
  a-brkt)

(define (set-ready-to-play a-brkt)
  (local (; current control panel
          (define a-ctrl-panel (breakout-ctrl-panel a-brkt))
          ; current player count
          (define a-game (ctrl-panel-game a-ctrl-panel))
          ; new breakout
          (define new-brkt
            (make-breakout (breakout-loba a-brkt)
                           (breakout-lop a-brkt)
                           (breakout-serve-num a-brkt)
                           (breakout-p1? a-brkt)
                           (breakout-p1 a-brkt)
                           (breakout-p2 a-brkt)
                           (breakout-high-scores a-brkt)
                           (breakout-credit-count a-brkt)
                           (breakout-ctrl-panel a-brkt)
                           (make-ready-to-play)
                           (breakout-next-silent-frame a-brkt))))
    (update-paddles
     (cond
       [(string=? a-game "double")
        (if (or (and (play-mode? (breakout-mode a-brkt))
                     (string=? a-game (play-mode-game (breakout-mode a-brkt))))
                (and (attract? (breakout-mode a-brkt))
                     (string=? a-game (attract-game (breakout-mode a-brkt)))))
            (reset-game (player-loba (breakout-p1 new-brkt))
                        (player-lobr (breakout-p1 new-brkt))
                        DOUBLE-PADDLES-0
                        new-brkt)
            (reset-game DOUBLE-BALLS-0
                        DOUBLE-BRICKS-0
                        DOUBLE-PADDLES-0
                        new-brkt))]
       [(string=? a-game "cavity")
        (if (or (and (play-mode? (breakout-mode a-brkt))
                                 (string=? a-game (play-mode-game (breakout-mode a-brkt))))
                            (and (attract? (breakout-mode a-brkt))
                                 (string=? a-game (attract-game (breakout-mode a-brkt)))))
            (reset-game (player-loba (breakout-p1 new-brkt))
                        (player-lobr (breakout-p1 new-brkt))
                        CAVITY-PADDLES-0
                        new-brkt)
            (reset-game CAVITY-BALLS-0
                        CAVITY-BRICKS-0
                        CAVITY-PADDLES-0
                        new-brkt))]
       [(string=? a-game "progressive")
        (if (or (and (play-mode? (breakout-mode a-brkt))
                     (string=? a-game (play-mode-game (breakout-mode a-brkt))))
                (and (attract? (breakout-mode a-brkt))
                     (string=? a-game (attract-game (breakout-mode a-brkt)))))
            (reset-game (player-loba (breakout-p1 new-brkt))
                        (player-lobr (breakout-p1 new-brkt))
                        PROGRESSIVE-PADDLES-0
                        new-brkt)
            (reset-game PROGRESSIVE-BALLS-0
                        PROGRESSIVE-BRICKS-0
                        PROGRESSIVE-PADDLES-0
                        new-brkt))]))))

(define (switch-game dir a-brkt0)
  (local (; current control panel
          (define a-ctrl-panel (breakout-ctrl-panel a-brkt0))
          ; current player count
          (define a-game (ctrl-panel-game a-ctrl-panel))
          ; new breakout
          (define a-brkt
            (if (play-mode? (breakout-mode a-brkt0))
                (make-breakout (breakout-loba a-brkt0)
                               (breakout-lop a-brkt0)
                               (breakout-serve-num a-brkt0)
                               (breakout-p1? a-brkt0)
                               (breakout-p1 a-brkt0)
                               (breakout-p2 a-brkt0)
                               (breakout-high-scores a-brkt0)
                               (breakout-credit-count a-brkt0)
                               a-ctrl-panel
                               (make-play-mode a-game #false #false)
                               (breakout-next-silent-frame a-brkt0))
                a-brkt0)))
    (update-paddles
     (if (string=? dir "next")
         (cond
           [(string=? a-game "double")
            a-brkt]
           [(string=? a-game "cavity")
            (reset-game DOUBLE-BALLS-0 DOUBLE-BRICKS-0 DOUBLE-PADDLES-0 a-brkt)]
           [(string=? a-game "progressive")
            (reset-game CAVITY-BALLS-0 CAVITY-BRICKS-0 CAVITY-PADDLES-0 a-brkt)])
         (cond
           [(string=? a-game "double")
            (reset-game CAVITY-BALLS-0 CAVITY-BRICKS-0 CAVITY-PADDLES-0 a-brkt)]
           [(string=? a-game "cavity")
            (reset-game PROGRESSIVE-BALLS-0 PROGRESSIVE-BRICKS-0 PROGRESSIVE-PADDLES-0 a-brkt)]
           [(string=? a-game "progressive")
            a-brkt])))))

(define (switch-ctrl-panel-game dir a-brkt)
  (local (; current control panel
          (define a-ctrl-panel (breakout-ctrl-panel a-brkt))
          ; current player count
          (define a-game (ctrl-panel-game a-ctrl-panel)))
    (if (string=? dir "next")
        (cond
          [(string=? a-game "double")
           a-brkt]
          [(string=? a-game "cavity")
           (set-ctrl-panel-game "double" a-brkt)]
          [(string=? a-game "progressive")
           (set-ctrl-panel-game "cavity" a-brkt)])
        (cond
          [(string=? a-game "double")
           (set-ctrl-panel-game "cavity" a-brkt)]
          [(string=? a-game "cavity")
           (set-ctrl-panel-game "progressive" a-brkt)]
          [(string=? a-game "progressive")
           a-brkt]))))

(define (set-ctrl-panel-game a-game a-brkt)
  (local (; current control panel
          (define a-ctrl-panel (breakout-ctrl-panel a-brkt)))
    (make-breakout (breakout-loba a-brkt)
                   (breakout-lop a-brkt)
                   (breakout-serve-num a-brkt)
                   (breakout-p1? a-brkt)
                   (breakout-p1 a-brkt)
                   (breakout-p2 a-brkt)
                   (breakout-high-scores a-brkt)
                   (breakout-credit-count a-brkt)
                   (make-ctrl-panel (ctrl-panel-player-count a-ctrl-panel)
                                    (ctrl-panel-paddle-posn a-ctrl-panel)
                                    a-game)
                   (breakout-mode a-brkt)
                   (breakout-next-silent-frame a-brkt))))

(define (set-ctrl-panel-paddle-posn x a-brkt)
  (local (; current control panel
          (define a-ctrl-panel (breakout-ctrl-panel a-brkt)))
    (make-breakout (breakout-loba a-brkt)
                   (breakout-lop a-brkt)
                   (breakout-serve-num a-brkt)
                   (breakout-p1? a-brkt)
                   (breakout-p1 a-brkt)
                   (breakout-p2 a-brkt)
                   (breakout-high-scores a-brkt)
                   (breakout-credit-count a-brkt)
                   (make-ctrl-panel (ctrl-panel-player-count a-ctrl-panel)
                                    x
                                    (ctrl-panel-game a-ctrl-panel))
                   (breakout-mode a-brkt)
                   (breakout-next-silent-frame a-brkt))))

;;;;;;;;;
;;; PLAY
;;;;;;;;;

(define (update-play a-brkt)
  (check-end-game (handle-end-serve (update-bricks (update-scores a-brkt)))))

;;;;;;;;;;;;;;;;;;;;;
;;; GENERAL HANDLING
;;;;;;;;;;;;;;;;;;;;;

; reset-game : List List List Breakout -> Breakout
(define (reset-game a-loba a-lobr a-lop a-brkt)
  (make-breakout '()
                 a-lop
                 (breakout-serve-num a-brkt)
                 (breakout-p1? a-brkt)
                 (make-player (player-score (breakout-p1 a-brkt))
                              a-loba
                              a-lobr)
                 (make-player (player-score (breakout-p2 a-brkt))
                              a-loba
                              a-lobr)
                 (breakout-high-scores a-brkt)
                 (breakout-credit-count a-brkt)
                 (breakout-ctrl-panel a-brkt)
                 (breakout-mode a-brkt)
                 (breakout-next-silent-frame a-brkt)))

; end-game
(define (end-game a-brkt)
  (if (positive? (breakout-credit-count a-brkt))
      (set-ready-to-play a-brkt)
      (local ((define a-game (play-mode-game (breakout-mode a-brkt)))
              (define new-brkt
                (make-breakout (breakout-loba a-brkt)
                               ATTRACT-PADDLES
                               (breakout-serve-num a-brkt)
                               (breakout-p1? a-brkt)
                               (breakout-p1 a-brkt)
                               (breakout-p2 a-brkt)
                               (breakout-high-scores a-brkt)
                               (breakout-credit-count a-brkt)
                               (breakout-ctrl-panel a-brkt)
                               (make-attract 2 a-game)
                               (breakout-next-silent-frame a-brkt))))
        (cond
          [(string=? a-game "double")
           (serve-ball 1 #true new-brkt)]
          [else (serve-ball 1 #false new-brkt)]))))

(define GAME-LENGTH 4)

(define (check-end-game a-brkt)
  (if (<= GAME-LENGTH (breakout-serve-num a-brkt))
      (end-game a-brkt)
      a-brkt))

(define (get-game a-brkt)
  (local ((define a-mode (breakout-mode a-brkt)))
    (cond
      [(play-mode? a-mode)
       (play-mode-game a-mode)]
      [(attract? a-mode)
       (attract-game a-mode)]
      [else
       (ctrl-panel-game (breakout-ctrl-panel a-brkt))])))

; update-bricks : Boolean Boolean Breakout -> Breakout
(define (update-bricks a-brkt)
  (local (; game
          (define a-game (get-game a-brkt))
          ; initial number of balls in 'a-game'
          (define num-balls-0
            (if (string=? "double" a-game)
                2 1))
          ; current Balls
          (define a-loba (breakout-loba a-brkt))
          ; update-player-bricks
          (define (update-player-bricks a-player)
            (local ((define new-bricks
                      (filter (lambda (a-brick)
                                (not (ormap (lambda (a-ball)
                                              (equal? a-brick (ball-tick-vobject a-ball)))
                                            a-loba)))
                              (player-lobr a-player))))
              (if (and (empty? new-bricks)
                       (= num-balls-0 (length a-loba))
                       (ormap (lambda (a-ball)
                                (paddle? (ball-tick-vobject a-ball)))
                              a-loba))
                  (make-player (player-score a-player)
                               (cond
                                 [(string=? "double" a-game)
                                  DOUBLE-BALLS-0]
                                 [(string=? "cavity" a-game)
                                  CAVITY-BALLS-0]
                                 [(string=? "progressive" a-game)
                                  PROGRESSIVE-BALLS-0])
                               (cond
                                 [(string=? "double" a-game)
                                  DOUBLE-BRICKS-0]
                                 [(string=? "cavity" a-game)
                                  CAVITY-BRICKS-0]
                                 [(string=? "progressive" a-game)
                                  PROGRESSIVE-BRICKS-0]))
                  (make-player (player-score a-player)
                               (player-loba a-player)
                               new-bricks)))))
    (make-breakout a-loba
                   (breakout-lop a-brkt)
                   (breakout-serve-num a-brkt)
                   (breakout-p1? a-brkt)
                   (if (breakout-p1? a-brkt)
                       (update-player-bricks (breakout-p1 a-brkt))
                       (breakout-p1 a-brkt))
                   (if (breakout-p1? a-brkt)
                       (breakout-p2 a-brkt)
                       (update-player-bricks (breakout-p2 a-brkt)))
                   (breakout-high-scores a-brkt)
                   (breakout-credit-count a-brkt)
                   (breakout-ctrl-panel a-brkt)
                   (breakout-mode a-brkt)
                   (breakout-next-silent-frame a-brkt))))

; called only in play mode
(define (update-scores a-brkt)
  (local (; current Balls
          (define a-loba (breakout-loba a-brkt))
          ; p1 score
          (define a-score
            (if (breakout-p1? a-brkt)
                (player-score (breakout-p1 a-brkt))
                (player-score (breakout-p2 a-brkt))))
          ; current mode
          (define a-mode (breakout-mode a-brkt))
          ; current game
          (define a-game (play-mode-game a-mode))
          ; tick score
          (define tick-score
            (apply + (map (lambda (a-ball)
                            (if (brick? (ball-tick-vobject a-ball))
                                (brick-point-value (brick-row (ball-tick-vobject a-ball))
                                                   (length a-loba)
                                                   a-game)
                                0))
                          a-loba)))
          ; new score
          (define new-score
            (+ a-score tick-score))
          ; current high score
          (define a-high-scores (breakout-high-scores a-brkt))
          ; beat-bonus?
          (define (beat-bonus? a-score)
            (>= new-score (get-bonus (play-mode-game a-mode))))
          ; update-player-score
          (define (update-player-score a-player)
            (make-player
             new-score
             (player-loba a-player)
             (player-lobr a-player))))
    (andplay-ticks
     tick-score
     (make-breakout (breakout-loba a-brkt)
                    (breakout-lop a-brkt)
                    (breakout-serve-num a-brkt)
                    (breakout-p1? a-brkt)
                    (if (breakout-p1? a-brkt)
                        (update-player-score (breakout-p1 a-brkt))
                        (breakout-p1 a-brkt))
                    (if (breakout-p1? a-brkt)
                        (breakout-p2 a-brkt)
                        (update-player-score (breakout-p2 a-brkt)))
                    (if (play-mode? a-mode)
                        (cond
                          [(string=? "cavity" (play-mode-game a-mode))
                           (make-high-scores (max (high-scores-cavity a-high-scores)
                                                  new-score)
                                             (high-scores-double a-high-scores)
                                             (high-scores-progressive a-high-scores))]
                          [(string=? "double" (play-mode-game a-mode))
                           (make-high-scores (high-scores-cavity a-high-scores)
                                             (max (high-scores-double a-high-scores)
                                                  new-score)
                                             (high-scores-progressive a-high-scores))]
                          [(string=? "progressive" (play-mode-game a-mode))
                           (make-high-scores (high-scores-cavity a-high-scores)
                                             (high-scores-double a-high-scores)
                                             (max (high-scores-progressive a-high-scores)
                                                  new-score))])
                        a-high-scores)
                    (+ (breakout-credit-count a-brkt)
                       (if (beat-bonus? new-score)
                           1 0))
                    (breakout-ctrl-panel a-brkt)
                    (breakout-mode a-brkt)
                    (breakout-next-silent-frame a-brkt)))))

(define RS-TICK-STREAM (make-pstream))
; - "tick" sounds when the ball hits a brick,
;   each representing one point of the brick's score point value
(define RS-TICK (rs-read "resources/sound/brick-1point.wav"))
; - "boop" sound when serve ends
(define RS-BOOP (rs-read "resources/sound/lose.wav"))
; - "blip" sound when the ball hits the paddle
(define RS-BLIP (rs-read "resources/sound/paddle.wav"))
; - "bounce" sound when the ball hits a boundary
(define RS-BOUNCE (rs-read "resources/sound/wall.wav"))

(define RS-TICK-LENGTH (rs-frames RS-TICK))

(define (andplay-ticks tick-score a-brkt)
  (local (; frame to play next ticks
          (define next-noise-frame (max (breakout-next-silent-frame a-brkt)
                                        (pstream-current-frame RS-TICK-STREAM)))
          ; frame to stop playing next ticks
          (define new-next-silent-frame (+ next-noise-frame
                                           (* RS-TICK-LENGTH tick-score))))
    (cond
      [(zero? tick-score)
       a-brkt]
      [(pstream? (pstream-set-volume! RS-TICK-STREAM 1))
       (andqueue RS-TICK-STREAM
                 (rs-append* (make-list tick-score RS-TICK))
                 next-noise-frame
                 (make-breakout (breakout-loba a-brkt)
                                (breakout-lop a-brkt)
                                (breakout-serve-num a-brkt)
                                (breakout-p1? a-brkt)
                                (breakout-p1 a-brkt)
                                (breakout-p2 a-brkt)
                                (breakout-high-scores a-brkt)
                                (breakout-credit-count a-brkt)
                                (breakout-ctrl-panel a-brkt)
                                (breakout-mode a-brkt)
                                new-next-silent-frame))])))

(define (serve a-game a-brkt)
  (cond
    [(string=? a-game "double")
     (serve-ball 1 #true a-brkt)]
    [else
     (serve-ball 1 #false a-brkt)]))

;;; Rendering
;;;;;;;;;;;;;;

; render : Breakout -> Image
; a rendered breakout game 'a-brkt'
(define (render a-brkt)
  (render-balls (append
                 (player-loba (if (breakout-p1? a-brkt)
                                  (breakout-p1 a-brkt)
                                  (breakout-p2 a-brkt)))
                 (breakout-loba a-brkt))
                (render-bricks (player-lobr (if (breakout-p1? a-brkt)
                                                (breakout-p1 a-brkt)
                                                (breakout-p2 a-brkt)))
                               (local (; current Mode in 'a-brkt'
                                       (define a-mode (breakout-mode a-brkt)))
                                 (cond
                                   [(attract? a-mode)
                                    (render-attract a-brkt)]
                                   [(ready-to-play? a-mode)
                                    (render-ready-to-play a-brkt)]
                                   [(play-mode? a-mode)
                                    (render-play a-brkt)])))))

; render-attract : Breakout -> Image
(define (render-attract a-brkt)
  (render-p1-score (player-score (breakout-p1 a-brkt))
                   #false
                   (render-p2-score (player-score (breakout-p2 a-brkt))
                                    #false
                                    (render-coin-mode (if (= 1 (attract-version
                                                                (breakout-mode a-brkt)))
                                                          0 (get-high-score (attract-game (breakout-mode a-brkt)) a-brkt))
                                                      PF-IMG))))

; render-ready-to-play : Breakout -> Image
(define (render-ready-to-play a-brkt)
  (render-paddles (breakout-lop a-brkt)
                  (render-p1-score (player-score (breakout-p1 a-brkt))
                                   #false
                                   (render-p2-score (player-score (breakout-p2 a-brkt))
                                                    #false
                                                    (render-bonus (ctrl-panel-game (breakout-ctrl-panel a-brkt))
                                                                  (render-coin-mode (get-high-score (ctrl-panel-game (breakout-ctrl-panel a-brkt)) a-brkt)
                                                                                    PF-IMG))))))

; render-play : Breakout -> Image
(define (render-play a-brkt)
  (render-paddles (breakout-lop a-brkt)
                  (render-serve-num (breakout-serve-num a-brkt)
                                    (render-p1-score (player-score (breakout-p1 a-brkt))
                                                     (breakout-p1? a-brkt)
                                                     (if (= 2 (ctrl-panel-player-count (breakout-ctrl-panel a-brkt)))
                                                         (render-p2-score (player-score (breakout-p2 a-brkt))
                                                                          (not (breakout-p1? a-brkt))
                                                                          (if (play-mode-has-one-serve? (breakout-mode a-brkt))
                                                                              PF-IMG
                                                                              (render-bonus (play-mode-game (breakout-mode a-brkt))
                                                                                            PF-IMG)))
                                                         (if (play-mode-has-one-serve? (breakout-mode a-brkt))
                                                             PF-IMG
                                                             (render-bonus (play-mode-game (breakout-mode a-brkt))
                                                                           PF-IMG)))))))
  
;;; Image helpers

(define (get-bonus a-game)
  (cond
    [(string=? a-game "cavity")
     1400]
    [(string=? a-game "double")
     1500]
    [(string=? a-game "progressive")
     2000]))

(define (get-high-score a-game a-brkt)
  (cond
    [(string=? a-game "cavity")
     (high-scores-cavity (breakout-high-scores a-brkt))]
    [(string=? a-game "double")
     (high-scores-double (breakout-high-scores a-brkt))]
    [(string=? a-game "progressive")
     (high-scores-progressive (breakout-high-scores a-brkt))]))

(define (render-bonus a-game bg-img)
  (place-image/align
   (string->bitmap
    27
    (string-append "BONUS FOR "
                   (number->atari-string
                    (get-bonus a-game))))
   (col->x 22)
   (row->y 27)
   "right" "top"
   bg-img))

(define (render-serve-num a-serve-num bg-img)
  (place-image/align (string->bitmap 31 (number->string (min (sub1 GAME-LENGTH) (floor a-serve-num))))
                     (col->x 14)
                     (row->y 31)
                     "right" "top"
                     bg-img))

; render-coin-mode : Image -> Image
(define (render-coin-mode high-score bg-img)
  (if (<= 0 (modulo (current-milliseconds) 2000) 1000)
      (if (zero? high-score)
          bg-img
          (place-image/align
           (string->bitmap 30 (string-append "HIGH SCORE "
                                             (number->atari-string high-score)))
           (col->x 21)
           (row->y 30)
           "right" "top"
           bg-img))
      (place-image/align
       (string->bitmap 30 "1 COIN  1 PLAYER")
       (col->x 21)
       (row->y 30)
       "right" "top"
       bg-img)))

(define (number->atari-string a-score)
  (local (; string
          (define score-string (number->string a-score))
          ; lenght
          (define score-string-length (string-length score-string)))
    (if (= 1 score-string-length)
        (string-append "  0" score-string)
        (string-append (replicate (- 4 score-string-length) " ")
                       score-string))))

; render-p1-score : Image -> Image
(define (render-p1-score a-score flashing? bg-img)
  (if (<= 0 (modulo (current-milliseconds) 500) 250)
      (if flashing?
          bg-img
          (place-image/align (string->bitmap 31 (number->atari-string a-score))
                             (col->x 7)
                             (row->y 31)
                             "right" "top"
                             bg-img))
      (place-image/align (string->bitmap 31 (number->atari-string a-score))
                         (col->x 7)
                         (row->y 31)
                         "right" "top"
                         bg-img)))

; render-p2-score : Image -> Image
(define (render-p2-score a-score flashing? bg-img)
  (if (<= 0 (modulo (current-milliseconds) 500) 250)
      (if flashing?
          bg-img
          (place-image/align (string->bitmap 31 (number->atari-string a-score))
                             (col->x 25)
                             (row->y 31)
                             "right" "top"
                             bg-img))
      (place-image/align (string->bitmap 31 (number->atari-string a-score))
                         (col->x 25)
                         (row->y 31)
                         "right" "top"
                         bg-img)))

; render-blocks : List<Block> Image -> Image
; a 'bg-img' with Bricks 'a-lobr' placed on it
(define (render-bricks a-lobr bg-img)
  (cond
    [(empty? a-lobr) bg-img]
    [else
     (local (; first Brick in 'a-lobr'
             (define a-brick (first a-lobr)))
       (place-image (crop (+ (col->x (brick-col a-brick)) (/ PF-SPACING 2))
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
       (if (positive? (ball-serve-delay a-ball))
           (render-balls (rest a-loba) bg-img)
           (place-image (crop (- (ball-x a-ball) BALL-RADIUS)
                              (- (ball-y a-ball) BALL-RADIUS)
                              (* 2 BALL-RADIUS)
                              (* 2 BALL-RADIUS)
                              OVERLAY-IMG)
                        (ball-x a-ball)
                        (ball-y a-ball)
                        (render-balls (rest a-loba) bg-img))))]))

; render-paddles : List<Paddle> Image -> Image
; a 'bg-img' with Paddles 'a-lop' placed on it
(define (render-paddles a-lop bg-img)
  (cond
    [(empty? a-lop) bg-img]
    [else
     (local (; first Paddle in 'a-lop'
             (define a-paddle (first a-lop)))
       (place-image/align (crop (+ (paddle-x a-paddle) (/ PF-SPACING 2))
                                (row->y (paddle-row a-paddle))
                                (- (paddle-width a-paddle) PF-SPACING)
                                IBRICK-HEIGHT
                                OVERLAY-IMG)
                          (+ (paddle-x a-paddle) (/ PF-SPACING 2))
                          (row->y (paddle-row a-paddle))
                          "left" "top"
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
         (key=? "a" key))
     (try-switch-game "prev" a-brkt)]
    [(or (key=? "right" key)
         (key=? "d" key))
     (try-switch-game "next" a-brkt)]
    [(key=? "1" key)
     (try-set-player-count 1 a-brkt)]
    [(key=? "2" key)
     (try-set-player-count 2 a-brkt)]
    [else a-brkt]))

(define (try-serve a-brkt)
  (local (; current Mode in 'a-brkt'
          (define a-mode (breakout-mode a-brkt)))
    (cond
      [(and (play-mode? a-mode)
            (empty? (breakout-loba a-brkt))
            (> GAME-LENGTH (breakout-serve-num a-brkt))
            (> (pstream-current-frame RS-TICK-STREAM)
               (breakout-next-silent-frame a-brkt)))
       (serve (play-mode-game a-mode) a-brkt)]
      [else
       (andplay ding a-brkt)])))

(define (try-insert-coin a-brkt)
  (local (; current mode
          (define a-mode (breakout-mode a-brkt))
          ; new breakout
          (define new-brkt
            (make-breakout (breakout-loba a-brkt)
                           (breakout-lop a-brkt)
                           (breakout-serve-num a-brkt)
                           (breakout-p1? a-brkt)
                           (breakout-p1 a-brkt)
                           (breakout-p2 a-brkt)
                           (breakout-high-scores a-brkt)
                           (local (; current credit count in 'a-brkt'
                                   (define credit-count (breakout-credit-count a-brkt)))
                             (if (<= 0 credit-count 14)
                                 (andplay click-1 (add1 credit-count))
                                 15))
                           (breakout-ctrl-panel a-brkt)
                           a-mode
                           (breakout-next-silent-frame a-brkt))))
    (if (attract? a-mode)
        (set-ready-to-play new-brkt)
        new-brkt)))

(define (try-switch-game dir a-brkt)
  (switch-ctrl-panel-game
   dir
   (if (or (ready-to-play? (breakout-mode a-brkt))
           (and (play-mode? (breakout-mode a-brkt))
                (not (play-mode-has-one-serve? (breakout-mode a-brkt)))))
       (switch-game dir a-brkt)
       (andplay ding a-brkt))))

(define (try-set-player-count n a-brkt)
  (if (ready-to-play? (breakout-mode a-brkt))
      (if (> n (breakout-credit-count a-brkt))
          (andplay ding a-brkt)
          (make-breakout (breakout-loba a-brkt)
                         (breakout-lop a-brkt)
                         1
                         #true
                         (get-player-0 (ctrl-panel-game (breakout-ctrl-panel a-brkt)))
                         (get-player-0 (ctrl-panel-game (breakout-ctrl-panel a-brkt)))
                         (breakout-high-scores a-brkt)
                         (- (breakout-credit-count a-brkt) n)
                         (make-ctrl-panel n
                                          (ctrl-panel-paddle-posn (breakout-ctrl-panel a-brkt))
                                          (ctrl-panel-game (breakout-ctrl-panel a-brkt)))
                         (make-play-mode (ctrl-panel-game (breakout-ctrl-panel a-brkt))
                                         #false
                                         #false)
                         (breakout-next-silent-frame a-brkt)))
      (andplay ding a-brkt)))

(define (get-player-0 a-game)
  (cond
    [(string=? a-game "double")
     (make-player 0 DOUBLE-BALLS-0 DOUBLE-BRICKS-0)]
    [(string=? a-game "cavity")
     (make-player 0 CAVITY-BALLS-0 CAVITY-BRICKS-0)]
    [(string=? a-game "progressive")
     (make-player 0 PROGRESSIVE-BALLS-0 PROGRESSIVE-BRICKS-0)]))

; handle-mouse : Breakout Number Number MouseEvent -> Breakout
(define (handle-mouse a-brkt x y mouse)
  (cond
    [(mouse=? mouse "move")
     (try-update-paddles
      (min (- (+ (col->x (sub1 PF-COL-COUNT)) PF-SPACING)
              (paddle-width (first (breakout-lop a-brkt))))
           (max (- x (/ (paddle-width (first (breakout-lop a-brkt))) 2))
                (- (col->x 1) PF-SPACING)))
      a-brkt)]
    [else
     a-brkt]))

(define (try-update-paddles x a-brkt)
  (local ((define new-brkt (set-ctrl-panel-paddle-posn x a-brkt)))
    (if (attract? (breakout-mode new-brkt))
        new-brkt
        (update-paddles new-brkt))))

(define (update-paddles a-brkt)
  (local ((define a-ctrl-panel (breakout-ctrl-panel a-brkt))
          (define x (ctrl-panel-paddle-posn a-ctrl-panel)))
       (make-breakout (breakout-loba a-brkt)
                      (map (lambda (a-paddle)
                             (make-paddle
                              x
                              (paddle-row a-paddle)
                              (paddle-width a-paddle)))
                           (breakout-lop a-brkt))
                      (breakout-serve-num a-brkt)
                      (breakout-p1? a-brkt)
                      (breakout-p1 a-brkt)
                      (breakout-p2 a-brkt)
                      (breakout-high-scores a-brkt)
                      (breakout-credit-count a-brkt)
                      a-ctrl-panel
                      (breakout-mode a-brkt)
                      (breakout-next-silent-frame a-brkt))))

;;; Main function
;;;;;;;;;;;;;;;;;;

; run : Breakout -> Breakout
; run the breakout game with initial state 'a-brkt0'
(define (run a-brkt0)
  (big-bang a-brkt0
    [on-tick update SPT]
    [state DEBUG?]
    [on-key handle-key]
    [on-mouse handle-mouse]
    [to-draw render]))

(define CAVITY-PADDLES-0
  (list (make-paddle (col->x 5) 29 PADDLE-WIDTH-0)))
(define DOUBLE-PADDLES-0
  (list (make-paddle (col->x 5) 24 PADDLE-WIDTH-0)
        (make-paddle (col->x 5) 29 PADDLE-WIDTH-0)))
(define PROGRESSIVE-PADDLES-0
  (list (make-paddle (col->x 5) 29 PADDLE-WIDTH-0)))

(define ATTRACT-PADDLES
  (build-list (/ (- PF-COL-COUNT 2) 2)
              (lambda (n) (make-paddle (col->x (+ (* 2 n) 1)) 29 BRICK-WIDTH))))

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
          (list (make-brick 1 7) (make-brick 3 7) (make-brick 5 7)
                (make-brick 11 7) (make-brick 13 7) (make-brick 15 7)
                (make-brick 21 7) (make-brick 23 7) (make-brick 25 7))
          (list (make-brick 1 8) (make-brick 3 8) (make-brick 5 8)
                (make-brick 11 8) (make-brick 13 8) (make-brick 15 8)
                (make-brick 21 8) (make-brick 23 8) (make-brick 25 8))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 9)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 10)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 11)))
          (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 12)))))

(define CAVITY-BALLS-0
  (list (make-ball (col->x 7.5) (row->y 8.5) CAVITY-BALL-SPEED (/ pi 4) NONE NONE 0 0 #false)
        (make-ball (col->x 17.5) (row->y 8) CAVITY-BALL-SPEED (/ pi 4) NONE NONE 0 0 #false)))
(define DOUBLE-BALLS-0 '())
(define PROGRESSIVE-BALLS-0 '())

(define SERVE-NUM-0 1)
(define P1?-0 #true)
(define P1-0 (make-player 0 CAVITY-BALLS-0 CAVITY-BRICKS-0))
(define P2-0 (make-player 0 CAVITY-BALLS-0 CAVITY-BRICKS-0))
(define HIGH-SCORES-0 (make-high-scores 0 0 0))
(define CREDIT-COUNT-0 0)
(define CTRL-PANEL-0 (make-ctrl-panel 1 (/ PF-WIDTH 2) "cavity"))
(define MODE-0 (make-attract 1 "cavity"))
(define NEXT-SILENT-FRAME-0 0)

(define ATTRACT-CAVITY-0
  (make-breakout '()
                 ATTRACT-PADDLES
                 SERVE-NUM-0
                 P1?-0
                 P1-0
                 P2-0
                 HIGH-SCORES-0
                 CREDIT-COUNT-0
                 CTRL-PANEL-0
                 MODE-0
                 NEXT-SILENT-FRAME-0))

(run (serve-ball 1 #false ATTRACT-CAVITY-0))
