;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname Fury_Breakout_2020) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))
(require 2htdp/image)
(require 2htdp/universe)
(require 2htdp/batch-io)
(require rsound)

;;; A clone of Super Breakout (Arcade, Atari, 1978)

;;;;;;;;;;;;;;
;;;
;;; Constants
;;;
;;;;;;;;;;;;;;

; seconds per clock tick
(define SPT 1/30)

; scale factor for entire canvas
(define SCALE-FACTOR 3)
; character block side length before scaling
(define CHAR-BLK-BIT-LENGTH 8)
; playfield spacing before scaling
(define PF-BIT-SPACING 2)
; ball radius before scaling
(define BALL-BIT-RADIUS 1.5)
; number of columns in playfield
(define PF-COL-COUNT 28)

; background color
(define BG-COLOR "black")
; foreground colors
(define FG-COLOR-0 "blue")
(define FG-COLOR-1 "orange")
(define FG-COLOR-2 "green")
(define FG-COLOR-3 "yellow")
(define FG-COLOR-4 "blue")
(define FG-COLOR-5 "white")
; number of rows each foreground color spans
(define FG-ROW-0 5)
(define FG-ROW-1 4)
(define FG-ROW-2 4)
(define FG-ROW-3 16)
(define FG-ROW-4 1)
(define FG-ROW-5 2)

; paddle width scale factor
(define PADDLE-SCALE-FACTOR 5/8)

; number of paddles hits per every game displayed during attract mode
(define PADDLE-HITS-PER-GAME 50)

; minimum and maximum ball speeds
(define BALL-MIN-SPEED 350)
(define BALL-MAX-SPEED 700)
; paddle hits before each (excluding the last) ball speed progression
(define PADDLE-HITS-BALL-PROGRESSION-0 1)
(define PADDLE-HITS-BALL-PROGRESSION-1 4)
(define PADDLE-HITS-BALL-PROGRESSION-2 8)
(define PADDLE-HITS-BALL-PROGRESSION-3 12)
; number of rows from top that include highpoint bricks
; (the last ball speed progression occurs after a highpoint-brick hit)
(define HIGHPOINT-BRICK-ROWS 9)
; ball directions in degrees
(define BALL-DIR-DEG-0 25)
(define BALL-DIR-DEG-1 40)
(define BALL-DIR-DEG-2 60)

; brick speeds (rows per paddle hit)
(define BRICK-SPEED-0 1/8)
(define BRICK-SPEED-1 1/4)
(define BRICK-SPEED-2 1/2)
(define BRICK-SPEED-3 1)
; paddle hits before each brick speed progression
(define PADDLE-HITS-BRICK-PROGRESSION-0 8)
(define PADDLE-HITS-BRICK-PROGRESSION-1 20)
(define PADDLE-HITS-BRICK-PROGRESSION-2 48)

; number of rows above the paddle to clear after every serve in the Progressive game mode
(define PROGRESSIVE-CLEAR-ROWS 4)

; coin mode blink duration in seconds
(define COIN-MODE-BLINK-DUR 2)
; score blink duration in seconds
(define SCORE-BLINK-DUR 1/2)

; upper right point of player score texts
(define P1-SCORE-COL 7)
(define P1-SCORE-ROW 31)
(define P2-SCORE-COL 25)
(define P2-SCORE-ROW 31)
; upper right point of serve number text
(define SERVE-NUM-COL 14)
(define SERVE-NUM-ROW 31)

; high score prefix displayed on canvas
(define HIGH-SCORE-PREFIX "HIGH SCORE ")
; coin mode displayed on canvas
(define COIN-MODE "1 COIN  1 PLAYER")
; upper right point of high score and coin mode text
(define COIN-MODE-COL 21)
(define COIN-MODE-ROW 30)

; bonus prefix displayed on canvas
(define BONUS-PREFIX "BONUS FOR ")
; upper right point of bonus text
(define BONUS-COL 22)
(define BONUS-ROW 27)

; credits added each time a player reaches a bonus score
(define BONUS-CREDITS 1)
; bonus score levels for each Super Breakout game
(define DOUBLE-BONUS 1500)
(define CAVITY-BONUS 1400)
(define PROGRESSIVE-BONUS 2000)

; maximum number of credits that can be accumulated
(define MAX-CREDIT-COUNT 15)
; number of credits per coin
(define CREDITS-PER-COIN 1)
; number of serves in a single game
(define GAME-LENGTH 3)

; brick point values
(define BRICK-POINT-VALUE-0 1)
(define BRICK-POINT-VALUE-1 3)
(define BRICK-POINT-VALUE-2 5)
(define BRICK-POINT-VALUE-3 7)
; first and last rows to which each brick point value applies
; for Double
(define DOUBLE-BPV-0-ROWI 5)
(define DOUBLE-BPV-0-ROWF 6)
(define DOUBLE-BPV-1-ROWI 7)
(define DOUBLE-BPV-1-ROWF 8)
(define DOUBLE-BPV-2-ROWI 9)
(define DOUBLE-BPV-2-ROWF 10)
(define DOUBLE-BPV-3-ROWI 11)
(define DOUBLE-BPV-3-ROWF 12)
; for Cavity
(define CAVITY-BPV-0-ROWI 5)
(define CAVITY-BPV-0-ROWF 6)
(define CAVITY-BPV-1-ROWI 7)
(define CAVITY-BPV-1-ROWF 8)
(define CAVITY-BPV-2-ROWI 9)
(define CAVITY-BPV-2-ROWF 10)
(define CAVITY-BPV-3-ROWI 11)
(define CAVITY-BPV-3-ROWF 12)
; for Progressive
(define PROGRESSIVE-BPV-0-ROWI 1)
(define PROGRESSIVE-BPV-0-ROWF 4)
(define PROGRESSIVE-BPV-1-ROWI 5)
(define PROGRESSIVE-BPV-1-ROWF 8)
(define PROGRESSIVE-BPV-2-ROWI 9)
(define PROGRESSIVE-BPV-2-ROWF 12)
(define PROGRESSIVE-BPV-3-ROWI 13)
(define PROGRESSIVE-BPV-3-ROWF 28)

; height of a group of bricks in each Super Breakout game
(define DOUBLE-BRICK-WALL-HEIGHT 8)
(define CAVITY-BRICK-WALL-HEIGHT 8)
(define PROGRESSIVE-BRICK-WALL-HEIGHT 4)

; game bricks
; paddle rows for each game

; the maximum number of active balls each game can start off with
(define CAVITY-MAX-NUM-BALLS-0 1)
(define DOUBLE-MAX-NUM-BALLS-0 2)
(define PROGRESSIVE-MAX-NUM-BALLS-0 1)

; paddle row numbers
(define CAVITY-PADDLE-ROW-NUMS '(29))
(define DOUBLE-PADDLE-ROW-NUMS '(24 29))
(define PROGRESSIVE-PADDLE-ROW 29)

; WAV file path of the tick sound
; (each tick represents one point of a brick's score point value)
(define RS-TICK-PATH "resources/sounds/brick-1point.wav")
; WAV file path of the boop sound
(define RS-BOOP-PATH "resources/sounds/lose.wav")
; WAV file path of the blip sound
(define RS-BLIP-PATH "resources/sounds/paddle.wav")
; WAV file path of the bounce sound
(define RS-BOUNCE-PATH "resources/sounds/wall.wav")

; a stream for the "tick" sounds
(define RS-TICK-STREAM (make-pstream))

; path of CSV file containing a 8x8 monochrome bitmap font
(define FONT-PATH "resources/fonts/Super_Breakout_Font_8x8.csv")

;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Derived constants
;;;
;;;;;;;;;;;;;;;;;;;;;;

; primary and secondary font colors
(define PRIMARY-FONT-COLOR FG-COLOR-5)
(define SECONDARY-FONT-COLOR FG-COLOR-3)

; coin mode blink duration in milliseconds
(define COIN-MODE-BLINK-DUR-MS (* COIN-MODE-BLINK-DUR 1000))
; score blink duration in milliseconds
(define SCORE-BLINK-DUR-MS (* SCORE-BLINK-DUR 1000))

; ball speed range
(define BALL-SPEED-RANGE (- BALL-MAX-SPEED BALL-MIN-SPEED))
; ball speeds (pixels per second)
(define BALL-SPEED-0 BALL-MIN-SPEED)
(define BALL-SPEED-1 (+ BALL-MIN-SPEED (* 1/5 BALL-SPEED-RANGE)))
(define BALL-SPEED-2 (+ BALL-MIN-SPEED (* 2/5 BALL-SPEED-RANGE)))
(define BALL-SPEED-3 (+ BALL-MIN-SPEED (* 3/5 BALL-SPEED-RANGE)))
(define BALL-SPEED-4 (+ BALL-MIN-SPEED (* 4/5 BALL-SPEED-RANGE)))
(define BALL-SPEED-5 BALL-MAX-SPEED)
; ball directions in degrees
(define BALL-DIR-RDN-0 (* BALL-DIR-DEG-0 pi 1/180))
(define BALL-DIR-RDN-1 (* BALL-DIR-DEG-1 pi 1/180))
(define BALL-DIR-RDN-2 (* BALL-DIR-DEG-2 pi 1/180))

; "tick" sound when the ball hits a 1-point brick
(define RS-TICK (rs-read RS-TICK-PATH))
; "boop" sound when serve ends
(define RS-BOOP (rs-read RS-BOOP-PATH))
; "blip" sound when the ball hits the paddle
(define RS-BLIP (rs-read RS-BLIP-PATH))
; "bounce" sound when the ball hits a boundary
(define RS-BOUNCE (rs-read RS-BOUNCE-PATH))

; number of frames in the tick sound
(define RS-TICK-LENGTH (rs-read-frames RS-TICK-PATH))
; number of frames in the boop sound
(define RS-BOOP-LENGTH (rs-read-frames RS-BOOP-PATH))

; character block side length after scaling
(define CHAR-BLK-LENGTH (* CHAR-BLK-BIT-LENGTH SCALE-FACTOR))
; playfield spacing after scaling
(define PF-SPACING (* PF-BIT-SPACING SCALE-FACTOR))
; ball radius after scaling
(define BALL-RADIUS (* BALL-BIT-RADIUS SCALE-FACTOR))

; number of rows in playfield
(define PF-ROW-COUNT (+ FG-ROW-0 FG-ROW-1 FG-ROW-2 FG-ROW-3 FG-ROW-4 FG-ROW-5))

; brick width in pixels
(define BRICK-WIDTH (* CHAR-BLK-LENGTH 2))
; brick height in pixels
(define BRICK-HEIGHT CHAR-BLK-LENGTH)
; illuminated brick width in pixels
(define IBRICK-WIDTH (- BRICK-WIDTH PF-SPACING))
; illuminated brick height in pixels
(define IBRICK-HEIGHT (- BRICK-HEIGHT PF-SPACING))

; normal paddle width
(define PADDLE-MAX-WIDTH BRICK-WIDTH)
; scaled paddle width
(define PADDLE-MIN-WIDTH (* PADDLE-SCALE-FACTOR BRICK-WIDTH))

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

; overlay images for each foreground color
(define OVERLAY-IMG-0
  (rectangle PF-WIDTH (* FG-ROW-0 BRICK-HEIGHT) "solid" FG-COLOR-0))
(define OVERLAY-IMG-1
  (rectangle PF-WIDTH (* FG-ROW-1 BRICK-HEIGHT) "solid" FG-COLOR-1))
(define OVERLAY-IMG-2
  (rectangle PF-WIDTH (* FG-ROW-2 BRICK-HEIGHT) "solid" FG-COLOR-2))
(define OVERLAY-IMG-3
  (rectangle PF-WIDTH (* FG-ROW-3 BRICK-HEIGHT) "solid" FG-COLOR-3))
(define OVERLAY-IMG-4
  (rectangle PF-WIDTH (* FG-ROW-4 BRICK-HEIGHT) "solid" FG-COLOR-4))
(define OVERLAY-IMG-5
  (rectangle PF-WIDTH (* FG-ROW-5 BRICK-HEIGHT) "solid" FG-COLOR-5))
; onr overlay image constructed by stacking the above overlays
(define OVERLAY-IMG
  (above OVERLAY-IMG-0
         OVERLAY-IMG-1
         OVERLAY-IMG-2
         OVERLAY-IMG-3
         OVERLAY-IMG-4
         OVERLAY-IMG-5))
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

;;;;;;;;;;;;;;;
;;;
;;; Data types
;;;
;;;;;;;;;;;;;;;

; a NonnegativeNumber is a Number greater than or equal to zero
; interpretation: a non-negative number

; a NonnegativeInteger is one of the following:
; - 0                         ; zero
; - (add1 NonnegativeInteger) : a positive Integer
; interpretation: a non-negative integer

; a Byte is an 8-character String of the following 1-letter Strings:
; - "0"
; - "1"
; interpretation: string of an 8-bit number

; a Pstream is (make-pstream)
; interpretation: an ongoing signal with a buffer time of about 50ms
; (define-struct pstream [])

; an Angle is a Number between (- pi) exclusive and pi inclusive
; interpretation: an angle in radians

; a Brick is (make-brick NonnegativeInteger NonnegativeInteger)
; interpretation: a brick in column number 'col' and row number 'row'
(define-struct brick [col row])

; a Paddle is (make-paddle Number NonnegativeInteger NonnegativeNumber)
; interpretation: a paddle with its left at 'x',
;                 its body in row number 'row',
;                 and a width of 'width'
(define-struct paddle [x row width])

; a Backwall is (make-backwall)
; interpretation: a wall stretched over the first row
(define-struct backwall [])

; a Frontwall is (make-frontwall)
; interpretation: a wall stretched over the last row
(define-struct frontwall [])

; a Nothing is (make-nothing)
; interpretation: nothing
(define-struct nothing [])

; a Ball is (make-ball cx cy speed dir rico-vobject tick-vobject paddle-hit-count serve-delay has-child?)
;    where cx, cy           : Number
;          speed            : NonnegativeNumber
;          dir              : Angle
;          rico-vobject     : VObject
;          tick-vobject     : VObject
;          paddle-hit-count : NonnegativeInteger
;          serve-delay      : NonnegativeNumber
;          has-child?       : Boolean
; interpretation: a ball, which collided with 'tick-vobject' in the last clock tick
;                 and most recently rebounded off of 'rico-vobject',
;                 with position ('cx', 'cy'), speed 'speed' in pixels per second,
;                 direction 'dir', and a paddle hit count of 'paddle-hit-count'
(define-struct ball [cx cy speed dir rico-vobject tick-vobject paddle-hit-count serve-delay has-child?])

; a VObject is one of the following:
; - a Brick
; - a Paddle
; - a Backwall
; - a Frontwall
; - a Nothing
; interpretation: an object that may rebound a ball vertically

; a Hitbox is (make-hitbox Number Number Number Number)
; interpretation: a hitbox with its upper left at ('left', 'top')
;                 and lower right at ('right', 'bottom')
(define-struct hitbox [left top right bottom])

; a ColorOverlay is (make-color-overlay Color NonnegativeInteger NonnegativeInteger)
; interpretation: a 'c' color overlay applied over rows 'i' inclusive to 'j' exclusive
(define-struct color-overlay [c i j])

; a Double is (make-double loba lobr lop bonus 

; a Game is one of the following Strings:
; - "double"
; - "cavity"
; - "progressive"
; interpretation: the name of one of the three Super Breakout games in Super Breakout

; an Attract is (make-attract Boolean Game)
; interpretaton: a Super Breakout mode called "attract"
;                displaying the game 'game' and holding an indicator
;                'v1?' to determine whether it is in version 1 or not
(define-struct attract [v1? game])

; a ReadyToPlay is (make-ready-to-play)
; interpretaton: a Super Breakout mode called "ready-to-play"
(define-struct ready-to-play [])

; a PlayMode is (make-play-mode game has-one-serve? end-serve?)
; interpretaton: a Super Breakout mode called "play"
;                displaying the game 'game' and holding two indicators
;                'has-one-serve?' and 'end-serve?'
;                to determine whether or not at least one ball has been served
;                and whether or not it should end the current serve
(define-struct play-mode [game has-one-serve? end-serve?])

; a Mode is one of the following Strings:
; - an Attract
; - a ReadyToPlay
; - a PlayMode
; interpretation: one of the three different modes of operation in Super Breakout

; a ControlPanel is (make-ctrl-panel one-player? paddle-posn game)
;    where one-player? : Boolean
;          paddle-posn : Number
;          game        : Game
; interpretation: a Super Breakout control panel keeping track of 3 values
;                 'one-player?', 'paddle-posn', and 'game' to determine
;                 whether or not there is one player playing,
;                 where the player(s) have positioned the paddle, and
;                 which game the player(s) have selected
(define-struct ctrl-panel [one-player? paddle-posn game])

; a HighScores is (make-high-scores cavity double progressive)
;    where cavity, double, and progressive : NonnegativeInteger
; interpretation: three high scores 'cavity', 'double', and 'progressive'
;                 corresponding to each Super Breakout game
(define-struct high-scores [cavity double progressive])

; a Player is (make-player score loba lobr progression-count)
;    where score             : NonnegativeInteger
;          loba              : List<Ball>
;          lobr              : List<Brick>
;          progression-count : NonnegativeInteger
; interpretation: a player with score 'score', captive balls 'loba',
;                 bricks 'lobr', and brick progression count 'progression-count'
(define-struct player [score loba lobr progression-count])

; a Breakout is (make-breakout loba lop serve-num p1 p2 high-scores credit-count ctrl-panel mode next-silent-frame)
;    where loba              : List<Ball>
;          lop               : List<Paddle>
;          serve-num         : NonnegativeNumber
;          p1                : Player
;          p2                : Player
;          high-scores       : HighScores
;          credit-count      : NonnegativeInteger
;          ctrl-panel        : ControlPanel
;          mode              : Mode
;          next-silent-frame : NonnegativeInteger
; interpretation: Super Breakout with active balls 'loba',
;                 paddles 'lop', serve number 'serve-num',
;                 player one 'p1' and two 'p2',
;                 high scores 'high-scores', credit count 'credit-count',
;                 control panel 'ctrl-panel', mode 'mode', and
;                 the next silent frame 'next-silent-frame'
(define-struct breakout
  [loba lop serve-num p1 p2 high-scores credit-count ctrl-panel mode next-silent-frame])

;;;;;;;;;;;;;;;;;;
;;;
;;; Data examples
;;;
;;;;;;;;;;;;;;;;;;

; col->x : NonnegativeInteger -> Number
; convert column number 'col' into a position in the x-coordinate
(define (col->x col)
  (* col CHAR-BLK-LENGTH))

; row->y : NonnegativeInteger -> Number
; convert row number 'row' into a position in the y-coordinate
(define (row->y row)
  (* row CHAR-BLK-LENGTH))

; Backwall
(define BACKWALL (make-backwall))
; Frontwall
(define FRONTWALL (make-frontwall))
; Nothing
(define NOTHING (make-nothing))

; Paddle
(define CAVITY-PADDLES-0
  (list (make-paddle 50 29 PADDLE-MAX-WIDTH)))
(define DOUBLE-PADDLES-0
  (list (make-paddle 50 24 PADDLE-MAX-WIDTH)
        (make-paddle 50 29 PADDLE-MAX-WIDTH)))
(define PROGRESSIVE-PADDLES-0
  (list (make-paddle 50 29 PADDLE-MAX-WIDTH)))

(define ATTRACT-PADDLES
  (build-list (/ (- PF-COL-COUNT 2) 2)
              (lambda (n) (make-paddle (col->x (+ (* 2 n) 1)) 29 BRICK-WIDTH))))

(define NEW-PROGRESSIVE-BRICKS
  (build-list (/ (- PF-COL-COUNT 2) 2) (lambda (n) (make-brick (+ (* 2 n) 1) 1))))
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
  (list (make-ball (col->x 7.5) (row->y 8.5) BALL-MIN-SPEED (/ pi 4) NOTHING NOTHING 0 0 #false)
        (make-ball (col->x 17.5) (row->y 8) BALL-MIN-SPEED (/ pi 4) NOTHING NOTHING 0 0 #false)))
(define DOUBLE-BALLS-0 '())
(define PROGRESSIVE-BALLS-0 '())

(define SERVE-NUM-0 1)
(define P1-0 (make-player 0 CAVITY-BALLS-0 CAVITY-BRICKS-0 0))
(define P2-0 (make-player 0 CAVITY-BALLS-0 CAVITY-BRICKS-0 0))
(define HIGH-SCORES-0 (make-high-scores 0 0 0))
(define CREDIT-COUNT-0 0)
(define CTRL-PANEL-0 (make-ctrl-panel #true (/ PF-WIDTH 2) "cavity"))
(define MODE-0 (make-attract #true "cavity"))
(define NEXT-SILENT-FRAME-0 0)

(define ATTRACT-CAVITY-0
  (make-breakout '()
                 ATTRACT-PADDLES
                 SERVE-NUM-0
                 P1-0
                 P2-0
                 HIGH-SCORES-0
                 CREDIT-COUNT-0
                 CTRL-PANEL-0
                 MODE-0
                 NEXT-SILENT-FRAME-0))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Additional constants and functions for custom font
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; byte-list->bitmap : Boolean List<Byte> -> Image
; convert a list of Bytes to a bitmap with depending on 'primary-font?'
(define (byte-list->bitmap primary-font? lob)
  (freeze
   (scale SCALE-FACTOR
          (color-list->bitmap (map (lambda (bit)
                                     (if (string=? bit "1")
                                         (if primary-font?
                                             PRIMARY-FONT-COLOR
                                             SECONDARY-FONT-COLOR)
                                         BG-COLOR))
                                   (explode (apply string-append lob)))
                              CHAR-BLK-BIT-LENGTH
                              CHAR-BLK-BIT-LENGTH))))

; vectors of character bitmaps corresponding to each font color
(define PRIMARY-CHAR-BITMAPS
  (list->vector
   (read-csv-file/rows FONT-PATH
                       (lambda (lob) (byte-list->bitmap #true lob)))))
(define SECONDARY-CHAR-BITMAPS
  (list->vector
   (read-csv-file/rows FONT-PATH
                       (lambda (lob) (byte-list->bitmap #false lob)))))

; string->bitmap : Boolean String -> Image
; convert a string to a bitmap with a font color depending on 'primary-font?'
(define (string->bitmap primary-font? str)
  (local (; 1string-list->bitmap : List<String> -> Image
          ; convert a list of 1-letter strings to a bitmap with a font color of 'color'
          (define (1string-list->bitmap strs)
            (cond
              [(empty? (rest strs))
               (1string->bitmap (first strs))]
              [else
               (beside (1string->bitmap (first strs))
                       (1string-list->bitmap (rest strs)))]))
          ; 1string->bitmap : Color String -> Image
          ; convert a 1-letter string to a bitmap with a font color of 'color'
          (define (1string->bitmap str)
            (vector-ref (if primary-font?
                            PRIMARY-CHAR-BITMAPS
                            SECONDARY-CHAR-BITMAPS)
                        (string->int str))))
  (1string-list->bitmap (explode str))))

; image of high score prefix text
(define HIGH-SCORE-PREFIX-IMG
  (string->bitmap #true HIGH-SCORE-PREFIX))
; image of coin mode text
(define COIN-MODE-IMG
  (string->bitmap #true COIN-MODE))
; image of bonus text for each Super Breakout game
(define DOUBLE-BONUS-IMG
  (string->bitmap #false (string-append BONUS-PREFIX
                                        (number->string DOUBLE-BONUS))))
(define CAVITY-BONUS-IMG
  (string->bitmap #false (string-append BONUS-PREFIX
                                        (number->string CAVITY-BONUS))))
(define PROGRESSIVE-BONUS-IMG
  (string->bitmap #false (string-append BONUS-PREFIX
                                        (number->string PROGRESSIVE-BONUS))))

;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Auxiliary functions
;;;
;;;;;;;;;;;;;;;;;;;;;;;;

#|
; col->x : NonnegativeInteger -> Number
; convert column number 'col' into a position in the x-coordinate
(define (col->x col)
  (* col CHAR-BLK-LENGTH))

; row->y : NonnegativeInteger -> Number
; convert row number 'row' into a position in the y-coordinate
(define (row->y row)
  (* row CHAR-BLK-LENGTH))
|#

; get-first : [X -> Boolean] List<X> -> Maybe<X>
; get the first element of list 'l' that satisfies predicate 'p?', if it exists;
; otherwise, return #false
(define (get-first p? l)
  (cond
    [(empty? l) #false]
    [else
     (local (; first element in 'l'
             (define first-l (first l)))
       (if (p? first-l)
           first-l
           (get-first p? (rest l))))]))

;; Hitbox

; brick->hitbox : Brick -> Hitbox
; get the hitbox of Brick 'a-brick'
(define (brick->hitbox a-brick)
  (local (; upper left point of 'a-brlck'
          (define x (col->x (brick-col a-brick)))
          (define y (row->y (brick-row a-brick)))
          ; top of the hitbox of 'a-brick'
          (define a-top (- y (/ IBRICK-HEIGHT 2))))
    (make-hitbox x
                 a-top
                 (+ x BRICK-WIDTH)
                 (+ a-top BRICK-HEIGHT))))

; paddle->hitbox : Paddle -> Hitbox
; get the hitbox of Paddle 'a-paddle'
(define (paddle->hitbox a-paddle)
  (local (; upper left point of 'a-paddle'
          (define x (paddle-x a-paddle))
          (define y (row->y (paddle-row a-paddle)))
          ; top of the hitbox of 'a-paddle'
          (define a-top (- y (/ (+ IBRICK-HEIGHT PF-SPACING) 2))))
    (make-hitbox (- x (/ PF-SPACING 2))
                 a-top
                 (+ x (paddle-width a-paddle) (/ PF-SPACING 2))
                 (+ y (- BRICK-HEIGHT (* PF-SPACING 3/2))))))

;; Sound

; try-andplay : Rsound Breakout X -> X
; try to play 'rsound', then return 'val'
(define (try-andplay rsound a-brkt val)
  (if (play-mode? (breakout-mode a-brkt))
      (andplay rsound val)
      val))

; try-andqueue-ticks : NonnegativeInteger Breakout -> Breakout
; queue the next sequence of 'tick-score' tick sound(s) in a Pstream and
; return a new 'a-brkt' with a new next silent frame
(define (try-andqueue-ticks tick-score a-brkt)
  (local (; frame to play next ticks
          (define next-noise-frame (max (breakout-next-silent-frame a-brkt)
                                        (pstream-current-frame RS-TICK-STREAM)))
          ; frame to stop playing next ticks
          (define new-next-silent-frame (+ next-noise-frame
                                           (* RS-TICK-LENGTH tick-score))))
    (cond
      [(and (pstream? (pstream-set-volume! RS-TICK-STREAM 1))
            (positive? tick-score)
            (play-mode? (breakout-mode a-brkt)))
       (andqueue RS-TICK-STREAM
                 (rs-append* (make-list tick-score RS-TICK))
                 next-noise-frame
                 (make-breakout (breakout-loba a-brkt)
                                (breakout-lop a-brkt)
                                (breakout-serve-num a-brkt)
                                (breakout-p1 a-brkt)
                                (breakout-p2 a-brkt)
                                (breakout-high-scores a-brkt)
                                (breakout-credit-count a-brkt)
                                (breakout-ctrl-panel a-brkt)
                                (breakout-mode a-brkt)
                                new-next-silent-frame))]
      [else a-brkt])))

;; Ball

; reflect-h : Angle -> Angle
; reflect Angle 'a' horizontally
(define (reflect-h a)
  (* (sgn a) (- pi (abs a))))

; move : Ball Breakout -> Ball
; move 'a-ball' for one clock tick considering the sidewalls only
(define (move a-ball a-brkt)
  (local (; direction of 'a-ball'
          (define a-dir (ball-dir a-ball))
          ; speed of 'a-ball' in pixels per tick
          (define tick-speed (* (ball-speed a-ball) SPT))
          ; number of pixels 'a-ball' moves horizontally and vertically
          (define vx (* (cos a-dir) tick-speed))
          (define vy (* (sin a-dir) tick-speed))
          ; final position of 'a-ball' after one clock tick
          ; without considering any collisions
          (define x2 (+ (ball-cx a-ball) vx))
          (define y2 (+ (ball-cy a-ball) vy)))
    (cond
      ; right sidewall collision
      [(>= x2 BALL-MAX-X)
       (try-andplay RS-BOUNCE
                    a-brkt
                    (make-ball BALL-MAX-X y2
                               (ball-speed a-ball)
                               (reflect-h (ball-dir a-ball))
                               (ball-rico-vobject a-ball)
                               NOTHING
                               (ball-paddle-hit-count a-ball)
                               (ball-serve-delay a-ball)
                               (ball-has-child? a-ball)))]
      ; left sidewall collision
      [(<= x2 BALL-MIN-X)
       (try-andplay RS-BOUNCE
                    a-brkt
                    (make-ball BALL-MIN-X y2
                               (ball-speed a-ball)
                               (reflect-h (ball-dir a-ball))
                               (ball-rico-vobject a-ball)
                               NOTHING
                               (ball-paddle-hit-count a-ball)
                               (ball-serve-delay a-ball)
                               (ball-has-child? a-ball)))]
      ; no collision
      [else
       (make-ball x2 y2
                  (ball-speed a-ball)
                  (ball-dir a-ball)
                  (ball-rico-vobject a-ball)
                  NOTHING
                  (ball-paddle-hit-count a-ball)
                  (ball-serve-delay a-ball)
                  (ball-has-child? a-ball))])))

; serve : Game Breakout -> Breakout
; serve one ball based on 'a-game' in 'a-brkt'
(define (serve a-game a-brkt)
  (cond
    [(string=? a-game "double")
     (serve-ball 1 #true a-brkt)]
    [else
     (serve-ball 1 #false a-brkt)]))

; serve-ball : NonnegativeNumber Breakout -> Breakout
; serve one random ball in 'a-brkt'
(define (serve-ball serve-delay has-child? a-brkt)
  (local ((define new-ball
            (make-ball (+ BALL-MIN-X (random (- BALL-MAX-X BALL-MIN-X -1)))
                       (/ PF-HEIGHT 2)
                       BALL-MIN-SPEED
                       (vector-ref ANGLES (random 4))
                       NOTHING
                       0 0 serve-delay has-child?)))
  (make-breakout (cons new-ball (breakout-loba a-brkt))
                 (breakout-lop a-brkt)
                 (breakout-serve-num a-brkt)
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

;; General

; get-game : Breakout -> Game
; return the current game in 'a-brkt'
(define (get-game a-brkt)
  (local (; current mode in 'a-brkt'
          (define a-mode (breakout-mode a-brkt)))
    (cond
      [(play-mode? a-mode)
       (play-mode-game a-mode)]
      [(attract? a-mode)
       (attract-game a-mode)]
      [else
       (ctrl-panel-game (breakout-ctrl-panel a-brkt))])))

; reset-game : List<Ball> List<Brick> List<Paddle> Breakout -> Breakout
; reset the game current displayed in 'a-brkt' to include 'a-loba', 'a-lobr', and 'a-lop'
(define (reset-game a-loba a-lobr a-lop a-brkt)
  (make-breakout '() a-lop
                 (breakout-serve-num a-brkt)
                 (make-player (player-score (breakout-p1 a-brkt))
                              a-loba a-lobr 0)
                 (make-player (player-score (breakout-p2 a-brkt))
                              a-loba a-lobr 0)
                 (breakout-high-scores a-brkt)
                 (breakout-credit-count a-brkt)
                 (breakout-ctrl-panel a-brkt)
                 (breakout-mode a-brkt)
                 (breakout-next-silent-frame a-brkt)))

;; Super Breakout modes

; set-attract : Boolean Game Breakout -> Breakout
; switch 'a-brkt' into attract mode with 'a-v1?' and 'a-game'
; and automatically serve a ball
(define (set-attract a-v1? a-game a-brkt)
  (serve a-game
         (make-breakout (breakout-loba a-brkt)
                        ATTRACT-PADDLES
                        (breakout-serve-num a-brkt)
                        (breakout-p1 a-brkt)
                        (breakout-p2 a-brkt)
                        (breakout-high-scores a-brkt)
                        (breakout-credit-count a-brkt)
                        (breakout-ctrl-panel a-brkt)
                        (make-attract a-v1? a-game)
                        (breakout-next-silent-frame a-brkt))))

; set-ready-to-play : Breakout -> Breakout
; switch 'a-brkt' into ready-to-play mode
(define (set-ready-to-play a-brkt)
  (local (; current control panel
          (define a-ctrl-panel (breakout-ctrl-panel a-brkt))
          ; game selected by a player
          (define a-game (ctrl-panel-game a-ctrl-panel))
          ; current mode
          (define a-mode (breakout-mode a-brkt))
          ; new breakout
          (define new-brkt
            (make-breakout (breakout-loba a-brkt)
                           (breakout-lop a-brkt)
                           (breakout-serve-num a-brkt)
                           (breakout-p1 a-brkt)
                           (breakout-p2 a-brkt)
                           (breakout-high-scores a-brkt)
                           (breakout-credit-count a-brkt)
                           (breakout-ctrl-panel a-brkt)
                           (make-ready-to-play)
                           (breakout-next-silent-frame a-brkt))))
    (update-paddle-x
     (if (or (and (play-mode? a-mode)
                  (string=? a-game (play-mode-game a-mode)))
             (and (attract? a-mode)
                  (string=? a-game (attract-game a-mode))))
         (reset-game (player-loba (breakout-p1 new-brkt))
                     (player-lobr (breakout-p1 new-brkt))
                     (cond
                       [(string=? a-game "double")
                        DOUBLE-PADDLES-0]
                       [(string=? a-game "cavity")
                        CAVITY-PADDLES-0]
                       [(string=? a-game "progressive")
                        PROGRESSIVE-PADDLES-0])
                     new-brkt)
         (cond
           [(string=? a-game "double")
            (reset-game DOUBLE-BALLS-0 DOUBLE-BRICKS-0 DOUBLE-PADDLES-0 new-brkt)]
           [(string=? a-game "cavity")
            (reset-game CAVITY-BALLS-0 CAVITY-BRICKS-0 CAVITY-PADDLES-0 new-brkt)]
           [(string=? a-game "progressive")
            (reset-game PROGRESSIVE-BALLS-0 PROGRESSIVE-BRICKS-0 PROGRESSIVE-PADDLES-0 new-brkt)])))))

; set-play : Breakout -> Breakout
; switch 'a-brkt' into play mode
(define (set-play a-brkt)
  (local (; current control panel
          (define a-ctrl-panel (breakout-ctrl-panel a-brkt))
          ; game selected by a player
          (define selected-game (ctrl-panel-game a-ctrl-panel))
          ; new player
          (define new-player
            (cond
              [(string=? selected-game "double")
               (make-player 0 DOUBLE-BALLS-0 DOUBLE-BRICKS-0 0)]
              [(string=? selected-game "cavity")
               (make-player 0 CAVITY-BALLS-0 CAVITY-BRICKS-0 0)]
              [(string=? selected-game "progressive")
               (make-player 0 PROGRESSIVE-BALLS-0 PROGRESSIVE-BRICKS-0 0)])))
    (make-breakout (breakout-loba a-brkt)
                   (breakout-lop a-brkt)
                   1 new-player new-player
                   (breakout-high-scores a-brkt)
                   (breakout-credit-count a-brkt)
                   a-ctrl-panel
                   (make-play-mode selected-game #false #false)
                   (breakout-next-silent-frame a-brkt))))

;;;;;;;;;;;;;;;;;;;;;;;

; require: (attract? (breakout-mode a-brkt)) is #false
(define (update-paddle-x a-brkt)
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
                   (breakout-p1 a-brkt)
                   (breakout-p2 a-brkt)
                   (breakout-high-scores a-brkt)
                   (breakout-credit-count a-brkt)
                   a-ctrl-panel
                   (breakout-mode a-brkt)
                   (breakout-next-silent-frame a-brkt))))

(define (switch-ctrl-panel-game key a-brkt)
  (local (; current control panel
          (define a-ctrl-panel (breakout-ctrl-panel a-brkt))
          ; current player count
          (define a-game (ctrl-panel-game a-ctrl-panel)))
    (cond
      [(or (key=? key "right")
           (key=? key "d"))
       (cond
         [(string=? a-game "double")
          a-brkt]
         [(string=? a-game "cavity")
          (set-ctrl-panel-game "double" a-brkt)]
         [(string=? a-game "progressive")
          (set-ctrl-panel-game "cavity" a-brkt)])]
      [(or (key=? key "left")
           (key=? key "a"))
       (cond
         [(string=? a-game "double")
          (set-ctrl-panel-game "cavity" a-brkt)]
         [(string=? a-game "cavity")
          (set-ctrl-panel-game "progressive" a-brkt)]
         [(string=? a-game "progressive")
          a-brkt])]
      [else a-brkt])))

(define (set-ctrl-panel-game a-game a-brkt)
  (local (; current control panel
          (define a-ctrl-panel (breakout-ctrl-panel a-brkt)))
    (make-breakout (breakout-loba a-brkt)
                   (breakout-lop a-brkt)
                   (breakout-serve-num a-brkt)
                   (breakout-p1 a-brkt)
                   (breakout-p2 a-brkt)
                   (breakout-high-scores a-brkt)
                   (breakout-credit-count a-brkt)
                   (make-ctrl-panel (ctrl-panel-one-player? a-ctrl-panel)
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
                   (breakout-p1 a-brkt)
                   (breakout-p2 a-brkt)
                   (breakout-high-scores a-brkt)
                   (breakout-credit-count a-brkt)
                   (make-ctrl-panel (ctrl-panel-one-player? a-ctrl-panel)
                                    x
                                    (ctrl-panel-game a-ctrl-panel))
                   (breakout-mode a-brkt)
                   (breakout-next-silent-frame a-brkt))))

(define (switch-displayed-game key a-brkt0)
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
                               (breakout-p1 a-brkt0)
                               (breakout-p2 a-brkt0)
                               (breakout-high-scores a-brkt0)
                               (breakout-credit-count a-brkt0)
                               a-ctrl-panel
                               (make-play-mode a-game #false #false)
                               (breakout-next-silent-frame a-brkt0))
                a-brkt0)))
    (update-paddle-x
     (cond
       [(or (key=? key "right")
            (key=? key "d"))
         (cond
           [(string=? a-game "double")
            a-brkt]
           [(string=? a-game "cavity")
            (reset-game DOUBLE-BALLS-0 DOUBLE-BRICKS-0 DOUBLE-PADDLES-0 a-brkt)]
           [(string=? a-game "progressive")
            (reset-game CAVITY-BALLS-0 CAVITY-BRICKS-0 CAVITY-PADDLES-0 a-brkt)])]
       [(or (key=? key "left")
            (key=? key "a"))
        (cond
          [(string=? a-game "double")
           (reset-game CAVITY-BALLS-0 CAVITY-BRICKS-0 CAVITY-PADDLES-0 a-brkt)]
          [(string=? a-game "cavity")
           (reset-game PROGRESSIVE-BALLS-0 PROGRESSIVE-BRICKS-0 PROGRESSIVE-PADDLES-0 a-brkt)]
          [(string=? a-game "progressive")
           a-brkt])]
       [else a-brkt]))))

(define (get-high-score a-game a-brkt)
  (cond
    [(string=? a-game "cavity")
     (high-scores-cavity (breakout-high-scores a-brkt))]
    [(string=? a-game "double")
     (high-scores-double (breakout-high-scores a-brkt))]
    [(string=? a-game "progressive")
     (high-scores-progressive (breakout-high-scores a-brkt))]))

(define (number->atari-string a-score)
  (local (; string
          (define score-string (number->string a-score))
          ; lenght
          (define score-string-length (string-length score-string)))
    (if (= 1 score-string-length)
        (string-append "  0" score-string)
        (string-append (replicate (- 4 score-string-length) " ")
                       score-string))))

; row->color : NonnegativeInteger -> Color
; convert row number 'row' into a Color
(define (row->color row)
  (cond
    [(< row FG-ROW-0)
     FG-COLOR-0]
    [(< row (+ FG-ROW-0 FG-ROW-1))
     FG-COLOR-1]
    [(< row (+ FG-ROW-0 FG-ROW-1 FG-ROW-2))
     FG-COLOR-2]
    [(< row (+ FG-ROW-0 FG-ROW-1 FG-ROW-2 FG-ROW-3))
     FG-COLOR-3]
    [(< row (+ FG-ROW-0 FG-ROW-1 FG-ROW-2 FG-ROW-3 FG-ROW-4))
     FG-COLOR-4]
    [else FG-COLOR-5]))

(define (player-one? a-brkt)
  (integer? (breakout-serve-num a-brkt)))

; get-dir : Number Paddle -> Angle
; get an angle of reflection of a point with horizontal position 'x'
; given that it collided with Paddle 'a-paddle'
(define (get-dir x paddle-hit-count ball-speed a-paddle)
  (local ((define a-hitbox (paddle->hitbox a-paddle))
          (define left (hitbox-left a-hitbox))
          (define right (hitbox-right a-hitbox))
          (define width (- right left)))
    (cond
      [(and (<= (+ left (* width 0/4)) x) (< x (+ left (* width 1/4))))
       (if (= BALL-MAX-SPEED ball-speed)
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
       (if (= BALL-MAX-SPEED ball-speed)
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
       (if (= BALL-MAX-SPEED ball-speed)
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
       (if (= BALL-MAX-SPEED ball-speed)
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

(define (get-speed paddle-hit-count vobject ball-speed)
  (max ball-speed
       (cond
         [(and (brick? vobject)
               (highpoint-brick? vobject))
          BALL-MAX-SPEED]
         [(paddle? vobject)
          (cond
            [(= 0 paddle-hit-count)
             (+ BALL-MIN-SPEED (* (- BALL-MAX-SPEED BALL-MIN-SPEED) 0/5))]
            [(= 1 paddle-hit-count)
             (+ BALL-MIN-SPEED (* (- BALL-MAX-SPEED BALL-MIN-SPEED) 1/5))]
            [(= 4 paddle-hit-count)
             (+ BALL-MIN-SPEED (* (- BALL-MAX-SPEED BALL-MIN-SPEED) 2/5))]
            [(= 8 paddle-hit-count)
             (+ BALL-MIN-SPEED (* (- BALL-MAX-SPEED BALL-MIN-SPEED) 3/5))]
            [(= 12 paddle-hit-count)
             (+ BALL-MIN-SPEED (* (- BALL-MAX-SPEED BALL-MIN-SPEED) 4/5))]
            [else
             ball-speed])]
         [else
          ball-speed])))

(define (highpoint-brick? a-brick)
  (<= 1 (brick-row a-brick) 8))

(define ANGLES (vector (* pi 1/4) (* pi 1/3) (* pi 2/3) (* pi 3/4)))

;;;;;;;;;;;;;;;;;;
;;;
;;; Tick handling
;;;
;;;;;;;;;;;;;;;;;;

; update : Breakout -> Breakout
; update 'a-brkt' for one clock tick
(define (update a-brkt0)
  (local (; updated 'a-brkt0' with new balls
          (define a-brkt (update-balls a-brkt0))
          ; current Mode in 'a-brkt'
          (define a-mode (breakout-mode a-brkt)))
    (cond
      [(attract? a-mode)
       (update-attract a-brkt)]
      [(play-mode? a-mode)
       (update-play a-brkt)]
      [else a-brkt])))

;;;;;;;;;;;;;;;;;;;;;;; BALLS ;;;;;;;;;;;;;;;;;;;;;;;

; update-balls : Breakout -> Breakout
; update the balls in 'a-brkt' as well as any other states
; that are directly affected by them
(define (update-balls a-brkt)
  (local (; current list of balls
          (define a-loba (breakout-loba a-brkt)))
    (cond
      [(empty? a-loba)
       a-brkt]
      [(ormap (lambda (a-ball)
                (positive? (ball-serve-delay a-ball)))
              a-loba)
       (make-breakout (map (lambda (a-ball)
                             (local (; serve delay of 'a-ball'
                                     (define a-serve-delay
                                       (ball-serve-delay a-ball)))
                               (if (positive? a-serve-delay)
                                   (make-ball (ball-cx a-ball)
                                              (ball-cy a-ball)
                                              (ball-speed a-ball)
                                              (ball-dir a-ball)
                                              (ball-rico-vobject a-ball)
                                              (ball-tick-vobject a-ball)
                                              (ball-paddle-hit-count a-ball)
                                              (- a-serve-delay SPT)
                                              (ball-has-child? a-ball))
                                   a-ball)))
                           a-loba)
                      (breakout-lop a-brkt)
                      (breakout-serve-num a-brkt)
                      (breakout-p1 a-brkt)
                      (breakout-p2 a-brkt)
                      (breakout-high-scores a-brkt)
                      (breakout-credit-count a-brkt)
                      (breakout-ctrl-panel a-brkt)
                      (breakout-mode a-brkt)
                      (breakout-next-silent-frame a-brkt))]
      [else
       (local (; updated balls
               (define updated-balls
                 (map (lambda (a-ball)
                        (update-ball a-ball #true a-brkt))
                      a-loba))
              ; updated balls excluding ones that hit the frontwall
              (define filtered-balls
                (filter (lambda (a-ball)
                          (not (frontwall? (ball-tick-vobject a-ball))))
                        updated-balls))
              ; players
              (define a-p1 (breakout-p1 a-brkt))
              (define a-p2 (breakout-p2 a-brkt))
              ; player one is playing?
              (define p1? (player-one? a-brkt))
              ; updated player balls
              (define updated-player-balls
                (map (lambda (a-ball)
                       (update-ball a-ball #false a-brkt))
                     (player-loba (if p1? a-p1 a-p2))))
              ; updated player balls excluding ones that hit the backwall or a paddle
              (define final-player-balls
                (filter (lambda (a-ball)
                          (not (or (backwall? (ball-tick-vobject a-ball))
                                   (paddle? (ball-tick-vobject a-ball)))))
                        updated-player-balls))
              ; excluded player balls
              (define excluded-player-balls
                (filter (lambda (a-ball)
                          (or (backwall? (ball-tick-vobject a-ball))
                              (paddle? (ball-tick-vobject a-ball))))
                        updated-player-balls))
              ; final balls
              (define final-balls (append excluded-player-balls filtered-balls))
              ; set-player-loba : Player -> Player
              ; set the balls 'a-player' to 'final-player-balls'
              (define (set-player-loba a-player)
                (make-player (player-score a-player)
                             final-player-balls
                             (player-lobr a-player)
                             (player-progression-count a-player)))
              ; breakout with all its balls updated
              (define final-brkt
                (make-breakout final-balls
                               (breakout-lop a-brkt)
                               (breakout-serve-num a-brkt)
                               (if p1? (set-player-loba a-p1) a-p1)
                               (if p1? a-p2 (set-player-loba a-p2))
                               (breakout-high-scores a-brkt)
                               (breakout-credit-count a-brkt)
                               (breakout-ctrl-panel a-brkt)
                               (breakout-mode a-brkt)
                               (breakout-next-silent-frame a-brkt)))
              ; serve-children : Breakout -> Breakout
              ; serve new balls in 'a-brkt'
              (define (serve-children a-brkt)
                (foldr (lambda (a-ball some-brkt)
                         (if (and (ball-has-child? a-ball)
                                  (= 1 (ball-paddle-hit-count a-ball))
                                  (paddle? (ball-tick-vobject a-ball)))
                             (serve-ball 0 #false some-brkt)
                             some-brkt))
                       a-brkt
                       (breakout-loba a-brkt)))
              ; handle-serve-just-ended : Breakout -> Breakout
              ; handle 'a-brkt' assuming that a serve just ended
              (define (handle-serve-just-ended a-brkt)
                (if (play-mode? (breakout-mode a-brkt))
                    (make-breakout
                     (breakout-loba a-brkt)
                     (breakout-lop a-brkt)
                     (breakout-serve-num a-brkt)
                     (breakout-p1 a-brkt)
                     (breakout-p2 a-brkt)
                     (breakout-high-scores a-brkt)
                     (breakout-credit-count a-brkt)
                     (breakout-ctrl-panel a-brkt)
                     (make-play-mode (play-mode-game (breakout-mode a-brkt))
                                     #true #true)
                     (if (and (pstream? (pstream-set-volume! RS-TICK-STREAM 0))
                              (void? (pstream-clear! RS-TICK-STREAM)))
                         (try-andplay RS-BOOP
                                      a-brkt
                                      (+ RS-BOOP-LENGTH
                                         (pstream-current-frame RS-TICK-STREAM)))
                         (error "something went wrong while trying to mute and clear a pstream")))
                    a-brkt)))
         (if (empty? final-balls)
             (handle-serve-just-ended final-brkt)
             (serve-children final-brkt)))])))

; update-ball : Ball Boolean Breakout -> Ball
; update 'a-ball' for one clock tick given 'a-brkt'
; and whether or not it is a active (not a player ball)
(define (update-ball a-ball active? a-brkt)
  (local (; current Bricks in 'a-brkt'
          (define a-lobr
            (player-lobr (if (player-one? a-brkt)
                             (breakout-p1 a-brkt)
                             (breakout-p2 a-brkt))))
          ; current Paddles in 'a-brkt'
          (define a-lop (breakout-lop a-brkt))
          ; moved 'a-ball' for one clock tick
          (define new-ball (move a-ball a-brkt))
          ; current game in 'a-brkt'
          (define a-game (get-game a-brkt))
          ; 'new-ball' position
          (define x3 (ball-cx new-ball))
          (define y3 (ball-cy new-ball))
          ; reflect-v : Angle -> Angle
          ; reflect Angle 'a' vertically
          (define (reflect-v a)
            (- a))
          ; brick-collision? : Ball Brick -> Boolean
          ; check whether 'a-ball' is in collision with 'a-brick'
          (define (brick-collision? a-ball a-brick)
            (local (; hitbox of 'a-brick'
                    (define a-hitbox (brick->hitbox a-brick))
                    ; position of the sides of 'a-hitbox'
                    (define left (hitbox-left a-hitbox))
                    (define top (hitbox-top a-hitbox))
                    (define right (hitbox-right a-hitbox))
                    (define bottom (hitbox-bottom a-hitbox))
                    ; the VObject 'a-ball' recently rebounded off of
                    (define rico-vobject (ball-rico-vobject a-ball)))
              (and (<= left (ball-cx a-ball) right)
                   (<= top (ball-cy a-ball) bottom)
                   (or (not active?)
                       (and (backwall? rico-vobject)
                            (< 1 (brick-row a-brick)))
                       (and (paddle? rico-vobject)
                            (< 1 (abs (- (paddle-row rico-vobject)
                                         (brick-row a-brick)))))
                       (and (brick? rico-vobject)
                            (< (cond
                                 [(string=? a-game "double")
                                  DOUBLE-BRICK-WALL-HEIGHT]
                                 [(string=? a-game "cavity")
                                  CAVITY-BRICK-WALL-HEIGHT]
                                 [(string=? a-game "progressive")
                                  PROGRESSIVE-BRICK-WALL-HEIGHT])
                               (abs (- (brick-row rico-vobject)
                                       (brick-row a-brick)))))))))
          ; paddle-collision? : Paddle -> Boolean
          ; check whether 'new-ball' is in collision with 'a-paddle'
          (define (paddle-collision? a-paddle)
            (local (; hitbox of 'a-brick'
                    (define a-hitbox (paddle->hitbox a-paddle))
                    ; positions of the sides of 'a-hitbox'
                    (define left (hitbox-left a-hitbox))
                    (define top (hitbox-top a-hitbox))
                    (define right (hitbox-right a-hitbox))
                    (define bottom (hitbox-bottom a-hitbox)))
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
                  (ball-speed new-ball)
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
                      (reflect-v (if (highpoint-brick? collided-brick)
                                     (local (; set-angle-60 : Angle -> Angle
                                             ; change Angle 'a' such that its reference angle is (/ pi 3)
                                             (define (set-angle-60 a)
                                               (if (< 0 (abs a) (/ pi 2))
                                                   (* (sgn a) pi 1/3)
                                                   (* (sgn a) pi 2/3))))
                                       (set-angle-60 (ball-dir new-ball)))
                                     (ball-dir new-ball)))
                      collided-brick
                      collided-brick
                      (ball-paddle-hit-count new-ball)
                      (ball-serve-delay new-ball)
                      (ball-has-child? new-ball))
           (local (; update-ball-dir : [Angle -> Angle] -> Ball
                   ; update the direction of 'new-ball'
                   (define (update-ball-dir fun)
                     (make-ball x3 y3
                                (ball-speed new-ball)
                                (fun (ball-dir new-ball))
                                collided-brick
                                collided-brick
                                (ball-paddle-hit-count new-ball)
                                (ball-serve-delay new-ball)
                                (ball-has-child? new-ball)))
                   ; 'new-ball' reflected horizontally and vertically respectively
                   (define new-ball-refh (update-ball-dir reflect-h))
                   (define new-ball-refv (update-ball-dir reflect-v)))
             (cond
               [(not (ormap (lambda (a-brick)
                              (brick-collision? (move new-ball-refh a-brkt) a-brick))
                            a-lobr))
                new-ball-refh]
               [(not (ormap (lambda (a-brick)
                              (brick-collision? (move new-ball-refv a-brkt) a-brick))
                            a-lobr))
                new-ball-refv]
               [else
                (update-ball-dir (compose reflect-h reflect-v))])))]
      ; paddle collision
      [(not (false? collided-paddle))
       (try-andplay RS-BLIP
                    a-brkt
                    (local (; new paddle hit cound
                            (define new-phc
                              (add1 (ball-paddle-hit-count new-ball)))
                            ; new speed
                            (define new-speed
                              (get-speed new-phc collided-paddle (ball-speed new-ball)))
                            ; new direction
                            (define new-dir
                              (get-dir x3 new-phc new-speed collided-paddle)))
                      (make-ball x3 y3
                                 new-speed
                                 new-dir
                                 collided-paddle
                                 collided-paddle
                                 new-phc
                                 (ball-serve-delay new-ball)
                                 (ball-has-child? new-ball))))]
      ; no collision
      [else
       (make-ball x3 y3
                  (ball-speed new-ball)
                  (ball-dir new-ball)
                  (ball-rico-vobject new-ball)
                  NOTHING
                  (ball-paddle-hit-count new-ball)
                  (ball-serve-delay new-ball)
                  (ball-has-child? new-ball))])))

;;;;;;;;;;;;;;;;;;;;;;; ATTRACT MODE ;;;;;;;;;;;;;;;;;;;;;;;

; update-attract : Breakout -> Breakout
; update Breakout 'a-brkt' in attract mode
(define (update-attract a-brkt)
  (local (; total paddle hit count of all balls in 'a-brkt'
          (define total-paddle-hit-count
            (apply + (map (lambda (a-ball)
                            (ball-paddle-hit-count a-ball))
                          (breakout-loba a-brkt)))))
    (cond
      [(>= total-paddle-hit-count PADDLE-HITS-PER-GAME)
       (switch-attract a-brkt)]
      [(attract-v1? (breakout-mode a-brkt))
       (update-bricks a-brkt)]
      [else a-brkt])))

; switch-attract : Breakout -> Breakout
; switch the game currently displayed in the attract mode of 'a-brkt'
; require: (attract? (breakout-mode a-brkt)) is #true
(define (switch-attract a-brkt)
  (local (; current Mode in 'a-brkt'
          (define a-attract (breakout-mode a-brkt))
          ; current Game in attract mode
          (define a-game (attract-game a-attract)))
    (cond
      [(string=? a-game "cavity")
       (set-attract #true "double"
                    (reset-game DOUBLE-BALLS-0 DOUBLE-BRICKS-0 '() a-brkt))]
      [(string=? a-game "double")
       (set-attract #true "progressive"
                    (reset-game PROGRESSIVE-BALLS-0 PROGRESSIVE-BRICKS-0 '() a-brkt))]
      [else
       (set-attract #true "cavity"
                    (reset-game CAVITY-BALLS-0 CAVITY-BRICKS-0 '() a-brkt))])))

;;;;;;;;;;;;;;;;;;;;;;; PLAY MODE ;;;;;;;;;;;;;;;;;;;;;;;

; update-play : Breakout -> Breakout
; update 'a-brkt' assuming it is in play mode
(define (update-play a-brkt)
  (check-end-game
   (handle-end-serve
    (update-bricks
     (update-score
      (update-paddle-width a-brkt))))))

; check-end-game : Breakout -> Breakout
; check if the game in 'a-brkt' ended, and handle 'a-brkt' if it did;
; otherwise, return 'a-brkt'
(define (check-end-game a-brkt)
  (if (< GAME-LENGTH (floor (breakout-serve-num a-brkt)))
      (if (positive? (breakout-credit-count a-brkt))
          (set-ready-to-play a-brkt)
          (set-attract #false (play-mode-game (breakout-mode a-brkt)) a-brkt))
      a-brkt))

; handle-end-serve : Breakout -> Breakout
; update 'a-brkt' for an end of serve
; require: (play-mode? (breakout-mode a-brkt)) is #true
(define (handle-end-serve a-brkt)
  (if (and (play-mode-end-serve? (breakout-mode a-brkt))
           (> (pstream-current-frame RS-TICK-STREAM)
              (breakout-next-silent-frame a-brkt)))
      (local (; current mode in 'a-brkt'
              (define a-mode (breakout-mode a-brkt))
              ; current game being played in 'a-brkt'
              (define a-game (play-mode-game a-mode))
              ; players
              (define a-p1 (breakout-p1 a-brkt))
              (define a-p2 (breakout-p2 a-brkt))
              ; whether or not player one is playing
              (define p1? (player-one? a-brkt))
              ; update-player-bricks : Player -> Player
              ; update the bricks of 'a-brick' to exclude the four rows
              (define (update-player-bricks a-player)
                (make-player (player-score a-player)
                             (player-loba a-player)
                             (if (string=? "progressive" a-game)
                                 (filter (lambda (a-brick)
                                           (> (- PROGRESSIVE-BRICK-WALL-HEIGHT 4)
                                              (brick-row a-brick)))
                                         (player-lobr a-player))
                                 (player-lobr a-player))
                             (player-progression-count a-player))))
        (make-breakout (breakout-loba a-brkt)
                       (map (lambda (a-paddle)
                              (make-paddle (paddle-x a-paddle)
                                           (paddle-row a-paddle)
                                           PADDLE-MAX-WIDTH))
                            (breakout-lop a-brkt))
                       (+ (breakout-serve-num a-brkt)
                          (if (ctrl-panel-one-player? (breakout-ctrl-panel a-brkt))
                              1 1/2))
                       (if p1? (update-player-bricks a-p1) a-p1)
                       (if p1? a-p2 (update-player-bricks a-p2))
                       (breakout-high-scores a-brkt)
                       (breakout-credit-count a-brkt)
                       (breakout-ctrl-panel a-brkt)
                       (make-play-mode a-game (play-mode-has-one-serve? a-mode) #false)
                       (breakout-next-silent-frame a-brkt)))
      a-brkt))

; update-bricks : Breakout -> Breakout
; update the bricks of the current player playing in 'a-brkt'
(define (update-bricks a-brkt)
  (local (; current game in 'a-brkt'
          (define a-game (get-game a-brkt))
          ; players
          (define a-p1 (breakout-p1 a-brkt))
          (define a-p2 (breakout-p2 a-brkt))
          ; whether or not player one is playing
          (define p1? (player-one? a-brkt))
          ; maximum initial number of active balls in 'a-game'
          (define max-num-balls-0
            (cond
              [(string=? "double" a-game) DOUBLE-MAX-NUM-BALLS-0]
              [(string=? "cavity" a-game) CAVITY-MAX-NUM-BALLS-0]
              [(string=? "progressive" a-game) PROGRESSIVE-MAX-NUM-BALLS-0]))
          ; current active Balls
          (define a-loba (breakout-loba a-brkt))
          ; total paddle hit count of all balls
          (define total-paddle-hit-count
            (apply + (map (lambda (a-ball)
                            (ball-paddle-hit-count a-ball))
                          a-loba)))
          ; update-player-bricks : Player -> Player
          ; update the bricks of 'a-player'
          (define (update-player-bricks a-player)
            (local (; new bricks based on what the balls 'a-loba' collided with
                    (define new-bricks
                      (filter (lambda (a-brick)
                                (not (ormap (lambda (a-ball)
                                              (equal? a-brick (ball-tick-vobject a-ball)))
                                            a-loba)))
                              (player-lobr a-player)))
                    ; current progression count for 'a-player'
                    (define ppc (player-progression-count a-player)))
              (cond
                [(and (string=? "progressive" a-game)
                      (play-mode? (breakout-mode a-brkt))
                      (ormap (lambda (a-ball)
                               (paddle? (ball-tick-vobject a-ball)))
                             a-loba)
                      (or (and (< PADDLE-HITS-BRICK-PROGRESSION-2
                                  total-paddle-hit-count)
                               (zero? (modulo total-paddle-hit-count (/ 1 BRICK-SPEED-3))))
                          (and (< PADDLE-HITS-BRICK-PROGRESSION-1
                                  total-paddle-hit-count)
                               (zero? (modulo total-paddle-hit-count (/ 1 BRICK-SPEED-2))))
                          (and (< PADDLE-HITS-BRICK-PROGRESSION-0
                                  total-paddle-hit-count)
                               (zero? (modulo total-paddle-hit-count (/ 1 BRICK-SPEED-1))))
                          (and (< 0 total-paddle-hit-count)
                               (zero? (modulo total-paddle-hit-count (/ 1 BRICK-SPEED-0))))))
                 ; progress bricks by one row
                 (make-player (player-score a-player)
                              (player-loba a-player)
                              (append (cond
                                        [(<= 0 (modulo ppc (* 2 PROGRESSIVE-BRICK-WALL-HEIGHT))
                                             (sub1 PROGRESSIVE-BRICK-WALL-HEIGHT))
                                         '()]
                                        [else
                                         NEW-PROGRESSIVE-BRICKS])
                                      (filter (lambda (a-brick)
                                                (> (sub1 PROGRESSIVE-PADDLE-ROW)
                                                   (brick-row a-brick)))
                                              (map (lambda (a-brick)
                                                     (make-brick (brick-col a-brick)
                                                                 (add1 (brick-row a-brick))))
                                                   new-bricks)))
                              (add1 ppc))]
                [(and (not (string=? "progressive" a-game))
                      (empty? new-bricks)
                      (>= max-num-balls-0 (length a-loba))
                      (ormap (lambda (a-ball)
                               (paddle? (ball-tick-vobject a-ball)))
                             a-loba))
                 (make-player (player-score a-player)
                              (cond
                                [(string=? "double" a-game)
                                 DOUBLE-BALLS-0]
                                [(string=? "cavity" a-game)
                                 CAVITY-BALLS-0])
                              (cond
                                [(string=? "double" a-game)
                                 DOUBLE-BRICKS-0]
                                [(string=? "cavity" a-game)
                                 CAVITY-BRICKS-0])
                              (add1 ppc))]
                [else
                 (make-player (player-score a-player)
                              (player-loba a-player)
                              new-bricks
                              ppc)]))))
    (make-breakout a-loba
                   (breakout-lop a-brkt)
                   (breakout-serve-num a-brkt)
                   (if p1? (update-player-bricks a-p1) a-p1)
                   (if p1? a-p2 (update-player-bricks a-p2))
                   (breakout-high-scores a-brkt)
                   (breakout-credit-count a-brkt)
                   (breakout-ctrl-panel a-brkt)
                   (breakout-mode a-brkt)
                   (breakout-next-silent-frame a-brkt))))

; update-score : Breakout -> Breakout
; update the score of the currently playing player in 'a-brkt'
; require: (play-mode (breakout-mode a-brkt) is #true
(define (update-score a-brkt)
  (local (; current Balls
          (define a-loba (breakout-loba a-brkt))
          ; players
          (define a-p1 (breakout-p1 a-brkt))
          (define a-p2 (breakout-p2 a-brkt))
          ; whether or not player one is playing
          (define p1? (player-one? a-brkt))
          ; the current score of the current player
          (define a-score
            (player-score (if p1? a-p1 a-p2)))
          ; current game
          (define a-game (play-mode-game (breakout-mode a-brkt)))
          ; the score received in the current tick
          (define tick-score
            (apply + (map (lambda (a-ball)
                            (local (; BObject 'a-ball' collided with during the current tick
                                    (define tick-vobject (ball-tick-vobject a-ball)))
                              (if (brick? tick-vobject)
                                  (brick-point-value (brick-row tick-vobject)
                                                     (length a-loba)
                                                     a-game)
                                  0)))
                          a-loba)))
          ; the new score
          (define new-score (+ a-score tick-score))
          ; current high scores
          (define a-high-scores (breakout-high-scores a-brkt))
          ; whether or not the current player beat the bonus of 'a-game'
          (define beat-bonus?
            (>= new-score (cond
                            [(string=? a-game "cavity")
                             CAVITY-BONUS]
                            [(string=? a-game "double")
                             DOUBLE-BONUS]
                            [(string=? a-game "progressive")
                             PROGRESSIVE-BONUS])))
          ; update-player-score : Player -> Player
          ; update the score of 'a-player' with 'new-score'
          (define (update-player-score a-player)
            (make-player new-score
                         (player-loba a-player)
                         (player-lobr a-player)
                         (player-progression-count a-player))))
    (try-andqueue-ticks
     tick-score
     (make-breakout (breakout-loba a-brkt)
                    (breakout-lop a-brkt)
                    (breakout-serve-num a-brkt)
                    (if p1? (update-player-score a-p1) a-p1)
                    (if p1? a-p2 (update-player-score a-p2))
                    (cond
                      [(string=? "cavity" a-game)
                       (make-high-scores (max (high-scores-cavity a-high-scores)
                                              new-score)
                                         (high-scores-double a-high-scores)
                                         (high-scores-progressive a-high-scores))]
                      [(string=? "double" a-game)
                       (make-high-scores (high-scores-cavity a-high-scores)
                                         (max (high-scores-double a-high-scores)
                                              new-score)
                                         (high-scores-progressive a-high-scores))]
                      [(string=? "progressive" a-game)
                       (make-high-scores (high-scores-cavity a-high-scores)
                                         (high-scores-double a-high-scores)
                                         (max (high-scores-progressive a-high-scores)
                                              new-score))])
                    (+ (breakout-credit-count a-brkt)
                       (if beat-bonus? BONUS-CREDITS 0))
                    (breakout-ctrl-panel a-brkt)
                    (breakout-mode a-brkt)
                    (breakout-next-silent-frame a-brkt)))))

; update-paddle-width : Breakout -> Breakout
; update the current width of the paddles in 'a-brkt'
(define (update-paddle-width a-brkt)
  (local (; the current list of paddles
          (define a-lop (breakout-lop a-brkt)))
    (make-breakout (breakout-loba a-brkt)
                   (if (and (play-mode? (breakout-mode a-brkt))
                            (ormap (lambda (a-ball)
                                     (backwall? (ball-tick-vobject a-ball)))
                                   (breakout-loba a-brkt)))
                       (map (lambda (a-paddle)
                              (make-paddle
                               (paddle-x a-paddle)
                               (paddle-row a-paddle)
                               PADDLE-MIN-WIDTH))
                            a-lop)
                       a-lop)
                   (breakout-serve-num a-brkt)
                   (breakout-p1 a-brkt)
                   (breakout-p2 a-brkt)
                   (breakout-high-scores a-brkt)
                   (breakout-credit-count a-brkt)
                   (breakout-ctrl-panel a-brkt)
                   (breakout-mode a-brkt)
                   (breakout-next-silent-frame a-brkt))))

;;;;;;;;;;;;;;
;;;
;;; Rendering
;;;
;;;;;;;;;;;;;;

; render : Breakout -> Image
; a rendered breakout game 'a-brkt'
(define (render a-brkt)
  (local (; the current player playing
          (define a-player
            (if (player-one? a-brkt)
                (breakout-p1 a-brkt)
                (breakout-p2 a-brkt)))
          ; current Mode in 'a-brkt'
          (define a-mode (breakout-mode a-brkt)))
    (render-balls (append (player-loba a-player) (breakout-loba a-brkt))
                  (render-bricks (player-lobr a-player)
                                 (cond
                                   [(attract? a-mode)
                                    (render-attract a-brkt)]
                                   [(ready-to-play? a-mode)
                                    (render-ready-to-play a-brkt)]
                                   [(play-mode? a-mode)
                                    (render-play a-brkt)])))))

; render-attract : Breakout -> Image
; render 'a-brkt' assuming it is in attract mode
; require: (attract? (breakout-mode a-brkt)) is #true
(define (render-attract a-brkt)
  (render-player-score (player-score (breakout-p1 a-brkt))
                       P1-SCORE-COL P1-SCORE-ROW #false
                       (render-player-score (player-score (breakout-p2 a-brkt))
                                            P2-SCORE-COL P2-SCORE-ROW #false
                                            (render-coin-mode (local (; current mode
                                                                      (define a-mode (breakout-mode a-brkt)))
                                                                (if (attract-v1? a-mode)
                                                                    0
                                                                    (get-high-score (attract-game a-mode) a-brkt)))
                                                              PF-IMG))))

; render-ready-to-play : Breakout -> Image
; render 'a-brkt' assuming it is in ready-to-play mode
; require: (ready-to-play? (breakout-mode a-brkt)) is #true
(define (render-ready-to-play a-brkt)
  (render-paddles (breakout-lop a-brkt)
                  (render-player-score (player-score (breakout-p1 a-brkt))
                                       P1-SCORE-COL P1-SCORE-ROW #false
                                       (render-player-score (player-score (breakout-p2 a-brkt))
                                                            P2-SCORE-COL P2-SCORE-ROW #false
                                                            (render-bonus (ctrl-panel-game (breakout-ctrl-panel a-brkt))
                                                                          (render-coin-mode (get-high-score (ctrl-panel-game
                                                                                                             (breakout-ctrl-panel a-brkt))
                                                                                                            a-brkt)
                                                                                            PF-IMG))))))

; render-play : Breakout -> Image
; render 'a-brkt' assuming it is in play mode
; require: (play-mode? (breakout-mode a-brkt)) is #true
(define (render-play a-brkt)
  (render-paddles (breakout-lop a-brkt)
                  (render-serve-num (breakout-serve-num a-brkt)
                                    (render-player-score (player-score (breakout-p1 a-brkt))
                                                         P1-SCORE-COL P1-SCORE-ROW
                                                         (player-one? a-brkt)
                                                         (local (; current mode
                                                                 (define a-mode (breakout-mode a-brkt))
                                                                 ; a 'PF-IMG' and maybe a bonus over it
                                                                 (define maybe-bonus-image
                                                                   (if (play-mode-has-one-serve? a-mode)
                                                                       PF-IMG
                                                                       (render-bonus (play-mode-game a-mode)
                                                                                     PF-IMG))))
                                                           (if (not (ctrl-panel-one-player? (breakout-ctrl-panel a-brkt)))
                                                               (render-player-score (player-score (breakout-p2 a-brkt))
                                                                                    P2-SCORE-COL P2-SCORE-ROW
                                                                                    (not (player-one? a-brkt))
                                                                                    maybe-bonus-image)
                                                               maybe-bonus-image))))))

; render-bonus : Game Image -> Image
; render the bonus score level on 'bg-img' given 'a-game'
(define (render-bonus a-game bg-img)
  (place-image/align (cond
                       [(string=? a-game "cavity")
                        CAVITY-BONUS-IMG]
                       [(string=? a-game "double")
                        DOUBLE-BONUS-IMG]
                       [(string=? a-game "progressive")
                        PROGRESSIVE-BONUS-IMG])
                     (col->x BONUS-COL)
                     (row->y BONUS-ROW)
                     "right" "top"
                     bg-img))

; render-serve-num : NonnegativeNumber Image -> Image
; render the current serve number 'a-serve-num' over 'bg-img'
(define (render-serve-num a-serve-num bg-img)
  (place-image/align (string->bitmap #true (number->string (min GAME-LENGTH
                                                                (floor a-serve-num))))
                     (col->x SERVE-NUM-COL)
                     (row->y SERVE-NUM-ROW)
                     "right" "top"
                     bg-img))

; render-coin-mode : Mode Image -> Image
; render the coin mode over 'bg-img' based on 'high-score' 
(define (render-coin-mode high-score bg-img)
  (if (<= 0 (modulo (current-milliseconds)
                    (* COIN-MODE-BLINK-DUR 1000))
          (* COIN-MODE-BLINK-DUR 500))
      (if (zero? high-score)
          bg-img
          (place-image/align (beside HIGH-SCORE-PREFIX-IMG
                                     (string->bitmap #false (number->atari-string high-score)))
                             (col->x COIN-MODE-COL)
                             (row->y COIN-MODE-ROW)
                             "right" "top"
                             bg-img))
      (place-image/align COIN-MODE-IMG
                         (col->x COIN-MODE-COL)
                         (row->y COIN-MODE-ROW)
                         "right" "top"
                         bg-img)))

; render-player-score : NonnegativeInteger NonnegativeInteger NonnegativeInteger Boolean Image -> Image
; render 'a-score' over 'bg-img' with its upper right at column 'col' and row 'row' based on 'flashing?'
(define (render-player-score a-score col rol flashing? bg-img)
  (local (; final image of 'a-score' over 'bg-img'
          (define score-img
            (place-image/align (string->bitmap #true (number->atari-string a-score))
                               (col->x col)
                               (row->y rol)
                               "right" "top"
                               bg-img)))
    (if (<= 0
            (modulo (current-milliseconds) SCORE-BLINK-DUR-MS)
            (/ SCORE-BLINK-DUR-MS 2))
        (if flashing? bg-img score-img)
        score-img)))

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
           (place-image (crop (- (ball-cx a-ball) BALL-RADIUS)
                              (- (ball-cy a-ball) BALL-RADIUS)
                              (* 2 BALL-RADIUS)
                              (* 2 BALL-RADIUS)
                              OVERLAY-IMG)
                        (ball-cx a-ball)
                        (ball-cy a-ball)
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

;;;;;;;;;;;;;;;;;
;;;
;;; Key handling
;;;
;;;;;;;;;;;;;;;;;

; handle-key : Breakout KeyEvent -> Breakout
; update 'a-brkt' based on 'key'
(define (handle-key a-brkt key)
  (cond
    [(key=? " " key)
     (try-serve a-brkt)]
    [(key=? "\r" key)
     (try-insert-coin a-brkt)]
    [(or (key=? "left" key)
         (key=? "a" key)
         (key=? "right" key)
         (key=? "d" key))
     (try-switch-game key a-brkt)]
    [(key=? "1" key)
     (try-set-player-one #true a-brkt)]
    [(key=? "2" key)
     (try-set-player-one #false a-brkt)]
    [else a-brkt]))

; try-serve : Breakout -> Breakout
; serve one ball in 'a-brkt' if possible
(define (try-serve a-brkt)
  (local (; current Mode in 'a-brkt'
          (define a-mode (breakout-mode a-brkt)))
    (cond
      [(and (play-mode? a-mode)
            (not (play-mode-end-serve? a-mode))
            (empty? (breakout-loba a-brkt))
            (>= GAME-LENGTH (floor (breakout-serve-num a-brkt))))
       (serve (play-mode-game a-mode) a-brkt)]
      [else
       (andplay ding a-brkt)])))

; try-insert-coin : Breakout -> Breakout
; insert a coin in 'a-brkt' if possible
(define (try-insert-coin a-brkt)
  (local (; current mode
          (define a-mode (breakout-mode a-brkt))
          ; new breakout
          (define new-brkt
            (make-breakout (breakout-loba a-brkt)
                           (breakout-lop a-brkt)
                           (breakout-serve-num a-brkt)
                           (breakout-p1 a-brkt)
                           (breakout-p2 a-brkt)
                           (breakout-high-scores a-brkt)
                           (local (; current credit count in 'a-brkt'
                                   (define credit-count (breakout-credit-count a-brkt))
                                   ; new credit count
                                   (define new-credit-count (+ CREDITS-PER-COIN credit-count)))
                             (if (>= new-credit-count MAX-CREDIT-COUNT)
                                 MAX-CREDIT-COUNT
                                 (andplay click-1 new-credit-count)))
                           (breakout-ctrl-panel a-brkt)
                           a-mode
                           (breakout-next-silent-frame a-brkt))))
    (if (attract? a-mode)
        (set-ready-to-play new-brkt)
        new-brkt)))

; try-switch-game : KeyEvent Breakout -> Breakout
; switch the control panel game as well as the displayed game 'a-brkt' if possible
(define (try-switch-game key a-brkt)
  (switch-ctrl-panel-game
   key
   (if (local (; current mode
               (define a-mode (breakout-mode a-brkt)))
         (or (ready-to-play? a-mode)
             (and (play-mode? a-mode)
                  (not (play-mode-has-one-serve? a-mode)))))
       (switch-displayed-game key a-brkt)
       (andplay ding a-brkt))))

; try-set-player-one : Breakout -> Breakout
; set how many players are playing in 'a-brkt' if possible
(define (try-set-player-one p1? a-brkt)
  (local (; 'p1?' as a number
          (define player-count (if p1? 1 2))
          ; current mode
          (define a-mode (breakout-mode a-brkt)))
    (if (and (ready-to-play? a-mode)
             (<= player-count (breakout-credit-count a-brkt)))
        (local (; current control panel
                (define a-ctrl-panel (breakout-ctrl-panel a-brkt)))
          (set-play (make-breakout (breakout-loba a-brkt)
                                   (breakout-lop a-brkt)
                                   (breakout-serve-num a-brkt)
                                   (breakout-p1 a-brkt)
                                   (breakout-p2 a-brkt)
                                   (breakout-high-scores a-brkt)
                                   (- (breakout-credit-count a-brkt) player-count)
                                   (make-ctrl-panel p1?
                                                    (ctrl-panel-paddle-posn a-ctrl-panel)
                                                    (ctrl-panel-game a-ctrl-panel))
                                   a-mode
                                   (breakout-next-silent-frame a-brkt))))
        (andplay ding a-brkt))))

;;;;;;;;;;;;;;;;;;;
;;;
;;; Mouse handling
;;;
;;;;;;;;;;;;;;;;;;;

; handle-mouse : Breakout Number Number MouseEvent -> Breakout
; update 'a-brkt' based on 'x', 'y', and 'mouse'
(define (handle-mouse a-brkt x y mouse)
  (local (; the list of paddles in 'a-brkt'
          (define a-lop (breakout-lop a-brkt)))
    (cond
      [(and (mouse=? mouse "move")
            (cons? a-lop))
       (local (; width of the first paddle in 'a-lop'
               (define first-paddle-width (paddle-width (first a-lop))))
         (try-update-paddle-x (min (- (+ (col->x (sub1 PF-COL-COUNT)) PF-SPACING)
                                      first-paddle-width)
                                   (max (- x (/ first-paddle-width 2))
                                        (- (col->x 1) PF-SPACING)))
                              a-brkt))]
      [else a-brkt])))

; try-update-paddle-x : Number Breakout -> Breakout
; update the paddle position of the control panel as well as
; of all the paddles in 'a-brkt' if possible
(define (try-update-paddle-x x a-brkt)
  (local (; new breakout with the control panel updated
          (define new-brkt (set-ctrl-panel-paddle-posn x a-brkt)))
    (if (attract? (breakout-mode new-brkt))
        new-brkt
        (update-paddle-x new-brkt))))

;;;;;;;;;
;;;
;;; Main
;;;
;;;;;;;;;

; run : Breakout -> Breakout
; run the breakout game with initial state 'a-brkt0'
(define (run a-brkt0)
  (big-bang a-brkt0
    [on-tick update SPT]
    [to-draw render]
    [on-key handle-key]
    [on-mouse handle-mouse]))

; use the Breakout (serve "cavity" ATTRACT-CAVITY-0)
; to run this program

(run (serve "cavity" ATTRACT-CAVITY-0))
