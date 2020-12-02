;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname Fury_Breakout_2020) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))

;;; Libraries
;;;;;;;;;;;;;;

; a library for drawing images
(require 2htdp/image)
; a library for making an interactive program
(require 2htdp/universe)
; a library for reading lines of files
(require 2htdp/batch-io)
; a library for splitting strings into substrings
(require racket/string)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Data types
;;;;;;;;;;;;;;;

; a Field is (make-field String Any)
; interpretation: a field named 'name' with content 'content'
(define-struct field [name content])

; a Record is a List<Field>
; interpretation: a list of Fields

;;; Data examples
;;;;;;;;;;;;;;;;;;

; Fields

(define F00 (make-field "date" "2012-02-12"))
(define F01 (make-field "carrier" "AA"))
(define F02 (make-field "number" "1176"))
(define F03 (make-field "origin" "MIA"))
(define F04 (make-field "destination" "BWI"))

(define F10 (make-field "date" "2011-01-04"))
(define F11 (make-field "carrier" "EV"))
(define F12 (make-field "number" "5119"))
(define F13 (make-field "origin" "ATL"))
(define F14 (make-field "destination" "LEX"))

(define F20 (make-field "date" "2012-02-23"))
(define F21 (make-field "carrier" "EV"))
(define F22 (make-field "number" "5059"))
(define F23 (make-field "origin" "GNV"))
(define F24 (make-field "destination" "ATL"))

; Records

(define R0 (list F00 F01 F02 F03 F04))
(define R1 (list F10 F11 F12 F13 F14))
(define R2 (list F20 F21 F22 F23 F24))

; List<String>s

(define LON '("date" "carrier" "number" "origin" "destination"))
(define LOC0 '("2012-02-12" "AA" "1176" "MIA" "BWI"))
(define LOC1 '("2011-01-04" "EV" "5119" "ATL" "LEX"))
(define LOC2 '("2012-02-23" "EV" "5059" "GNV" "ATL"))

;;; Function get-field
;;;;;;;;;;;;;;;;;;;;;;;

;; Input/output
; get-field : String Record -> Any
; return the content of a Field named 'name' in 'record'
;    if one exists; otherwise, return #false
; header: (define (get-field name record) #false)

;; Examples
(check-expect (get-field "date"        R0) "2012-02-12")
(check-expect (get-field "carrier"     R0) "AA")
(check-expect (get-field "number"      R1) "5119")
(check-expect (get-field "origin"      R1) "ATL")
(check-expect (get-field "destination" R2) "ATL")
(check-expect (get-field "flight"      R2) #false)

;; Template
; (define (get-field name record)
;   (cond
;     [(empty? record) (... name ... record ...)]
;     [else
;      (... name ... record ...
;           (first record) ...
;           (rest record) ...
;           (field-name (first record)) ...
;           (field-content (first record)) ...
;           (get-field ... (rest record)) ...)]))

;; Code
(define (get-field name record)
  (cond
    [(empty? record) #false]
    [else
     (local (; the first Field in 'record'
             (define first-field (first record)))
       (if (string=? name (field-name first-field))
           (field-content first-field)
           (get-field name (rest record))))]))

;;; Function list->record
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Input/output
; list->record : List<String> List -> Record
; require: 'lon' and 'loc' have the same number of elements
; return a Record by pairing names 'lon' and contents 'loc' in order
; header: (define (list->record lon loc) R0)

;; Examples
(check-expect (list->record LON LOC0) R0)
(check-expect (list->record LON LOC1) R1)
(check-expect (list->record LON LOC2) R2)

;; Template
; (define (list->record lon loc)
;   (cond
;     [(empty? lon) (... lon ... loc ...)]
;     [else
;      (... lon ... loc ...
;           (first lon) ... (first loc) ...
;           (rest lon) ... (rest loc) ...
;           (list->record (rest lon) (rest loc)) ...)]))

;; Code
(define (list->record lon loc)
  (cond
    [(empty? lon) '()]
    [else
     (cons (make-field (first lon) (first loc))
           (list->record (rest lon) (rest loc)))]))

;;; Function read-csv
;;;;;;;;;;;;;;;;;;;;;;

;; Input/output
; read-csv : String -> List<Record>
; require: a CSV file named 'f' exists;
;          the file is not empty; and
;          each row of the file has the same number of values
; return a list of Records in a CSV file named 'f'
; header: (define (read-csv f) '())

;; Examples
;(check-expect (first (read-csv test-file)) R0)
;(check-expect (first (rest (read-csv test-file))) R1)
;(check-expect (first (first (read-csv test-file))) F00)
;(check-expect (first (first (rest (read-csv test-file)))) F10)
;(check-expect (length (read-csv test-file)) 1000)

;; Template
; (define (read-csv f)
;   (... f ... (read-lines f) ...))

;; Code
(define (read-csv f)
  (local (; a list of Strings, each of which
          ;    correspond to a line in the CSV file named 'f'
          (define lines (read-lines f))
          ; string->list : String -> List<String>
          ; return a list of substrings of 'str' that are
          ;    separated by a comma
          ; header: (define (string->list str) '())
          (define (string->list str)
            (string-split str ","))
          ; a list of Field names, which is given in the CSV file's header
          (define field-names (string->list (first lines))))
    (list->vector
     (map (lambda (line)
            (list->record field-names (string->list line)))
          (rest lines)))))

(define (string->image str)
  (char-list->image
   (explode
    (string-upcase str))))

(define (char-list->image loc)
  (cond
    [(empty? loc) empty-image]
    [(empty? (rest loc)) (char->image (first loc))]
    [else
     (beside (char->image (first loc))
             (char-list->image (rest loc)))]))

;(define (char->image c)
;  (color-list->bitmap
;    (char->color-list c)
;    8 8))

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

; name of CSV file containing a 8x8 monochrome bitmap font
(define FONT-FILENAME "Super_Breakout_Font_8x8.csv")
; list of character bitmaps
(define CHAR-BITMAPS
  (list->vector (read-csv-file/rows FONT-FILENAME char-bitmap)))

; char-bitmap : List<Byte> -> Image
(define (char-bitmap lob)
  (color-list->bitmap
   (map (lambda (bit) (if (string=? bit "1") "white" "black"))
        (explode (apply string-append* lob)))
   8 8))

(define (hex->binary hex)
  (string-replace
   (string-replace
    (string-replace
     (string-replace
      (string-replace
       (string-replace
        (string-replace
         (string-replace
          (string-replace
           (string-replace
            (string-replace
             (string-replace
              (string-replace
               (string-replace
                (string-replace
                 (string-replace
                  (string-replace hex "0x" "")
                  "f" "1111")
                 "e" "1110")
                "d" "1101")
               "c" "1100")
              "b" "1011")
             "a" "1010")
            "9" "1001")
           "8" "1000")
          "7" "0111")
         "6" "0110")
        "5" "0101")
       "4" "0100")
      "3" "0011")
     "2" "0010")
    "1" "0001")
   "0" "0000"))

;(define (char->color-list c)
;  (local ((define records
;            (read-csv "char-bitmaps-v2.csv"))
;          (define record
;            (get-first (lambda (record)
;                         (string=? c (get-field "char" record)))
;                       records))
;          (define (record->bits record)
;            (build-string (* 8 8) (lambda (i) (string-ref (get-field (string-append "byte" (number->string (floor (/ i 8))))
;                                                                     record)
;                                                          (modulo i 8)))))
;          (define bits (record->bits record)))
;    (map (lambda (bit)
;           (cond
;             [(string=? bit "0") "black"]
;             [(string=? bit "1") "white"]))
;       (explode bits))))

(define (char->image c)
  (local ((define record (vector-ref CHAR-BITMAPS (string->int c)))
          (define (record->bits record)
            (build-list 8 (lambda (i) (explode (get-field (string-append "row" (number->string i))
                                                          record)))))
          (define bits (record->bits record)))
    (bit-2d-list->bitmap bits)))

(define (bit-2d-list->bitmap lolob)
  (cond
    [(empty? lolob) empty-image]
    [else
     (above (bit-1d-list->bitmap (first lolob))
            (bit-2d-list->bitmap (rest lolob)))]))

(define (bit-1d-list->bitmap lob)
  (cond
    [(empty? lob) empty-image]
    [else
     (beside (square 1 "solid"
                     (if (string=? (first lob) "0")
                         "black" "white"))
             (bit-1d-list->bitmap (rest lob)))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Data types
;;;;;;;;;;;;;;;

; a NonnegativeNumber is a Number greater than or equal to zero
; interpretation: a non-negative number

; a NonnegativeInteger is one of the following:
; - 0                         ; zero
; - (add1 NonnegativeInteger) : a positive Integer
; interpretation: a non-negative integer

; a Natural is one of the following:
; - 1                         ; one
; - (add1 NonnegativeInteger) : an Integer greater than one
; interpretation: a natural number

; an Angle is between (- pi) exclusive and pi inclusive
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
(define-struct ball [x y speed dir last-vobject paddle-hit-count])

; a CollisionGeometry is (make-collision-geometry Number Number Number Number)
; interpretation: a rectangle with top left corner positioned at ('left', 'top')
;                 and bottom right corner positioned at ('right', 'bottom') in pixels
(define-struct collision-geometry [left top right bottom])

; a ColorOverlay is (make color-overlay Color NonnegativeInteger NonnegativeInteger)
; interpretation: a color overlay applied over rows 'i' inclusive to 'j' exclusive
(define-struct color-overlay [c i j])

; an AttractVersion is either 1 or 2
; interpretation: an attract mode version in Super Breakout

; an Attract is (make-attract AttractVersion)
; interpretaton: a Super Breakout mode called "attract"
(define-struct attract [version])

; an ReadyToPlay is (make-ready-to-play)
; interpretaton: a Super Breakout mode called "ready-to-play"
(define-struct ready-to-play [])

; a Play is (make-play)
; interpretaton: a Super Breakout mode called "play"
(define-struct play [])

; a Mode is one of the following Strings:
; - "attract"
; - "ready-to-play"
; - "play"
; interpretation: the name of one of the three different modes of operation
;                 in Super Breakout

; a Game is one of the following Strings:
; - "double"
; - "cavity"
; - "progressive"
; interpretation: the name of one of the three Super Breakout games
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
  [loba lobr lop score high-score credit-count second-count ctrl-panel mode])

(define SCORE-0 0)
(define HIGH-SCORE-0 0)
(define CREDIT-COUNT-0 15)
(define SECOND-COUNT-0 0)
(define CTRL-PANEL-0 (make-ctrl-panel #true 0 "cavity" #false #false))
(define MODE-0 "attract")

;;; Constants
;;;;;;;;;;;;;;

; seconds per clock tick
(define SPT 1/60)
; whether to debug or not
(define DEBUG? #false)
; bit width in pixels
(define BIT-WIDTH 3)

; character block length in pixels
(define CHAR-BLK-LENGTH (* 8 BIT-WIDTH))

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

; background image
(define BG-IMG (rectangle PF-WIDTH PF-HEIGHT "solid" BG-COLOR))
; backwall length
(define BACKWALL-LENGTH (- PF-WIDTH PF-SPACING (* 2 WALL-THICKNESS)))
; backwall image
(define BACKWALL-IMG (rectangle BACKWALL-LENGTH
                                WALL-THICKNESS
                                "solid"
                                (color-overlay-c (first FG-COLORS))))
; sidewall image
(define SIDEWALL-IMG
  (local ((define (generate-sidewall-img/acc loc img)
            (cond
              [(empty? loc) img]
              [else
               (local ((define a-color-overlay (first loc))
                       (define a-c (color-overlay-c a-color-overlay))
                       (define a-i (color-overlay-i a-color-overlay))
                       (define a-j (color-overlay-j a-color-overlay)))
                 (above img
                        (generate-sidewall-img/acc
                         (rest loc)
                         (rectangle WALL-THICKNESS
                                    (if (zero? a-i)
                                        (- (* (- a-j a-i) BRICK-HEIGHT) (/ PF-SPACING 2))
                                        (* (- a-j a-i) BRICK-HEIGHT))
                                    "solid" a-c))))])))
    (generate-sidewall-img/acc FG-COLORS empty-image)))
; playfield image
(define PF-IMG
  (overlay/align
   "center" "bottom"
   (beside SIDEWALL-IMG
           (overlay/align
            "center" "top"
            BACKWALL-IMG
            (rectangle BACKWALL-LENGTH
                       (image-height SIDEWALL-IMG)
                       "solid" "transparent"))
           SIDEWALL-IMG)
   BG-IMG))

;;; Auxiliary functions
;;;;;;;;;;;;;;;;;;;;;;;;

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

; remove-bricks : List<Ball> List<Brick> -> List<Brick>
; remove Bricks from a list of Bricks 'a-lobr' given a list of Balls 'a-loba'
(define (remove-bricks a-loba a-lobr)
  (cond
    [(empty? a-loba) a-lobr]
    [else
     (remove (ball-last-vobject (first a-loba))
             (remove-bricks (rest a-loba) a-lobr))]))

;;; Tick handling
;;;;;;;;;;;;;;;;;;

; update : Breakout -> Breakout
; update Breakout 'a-brkt' for one clock tick
(define (update a-brkt)
  (local (; current Blocks in 'a-brkt'
          (define a-lobr (breakout-lobr a-brkt))
          ; current Balls in 'a-brkt'
          (define a-loba (breakout-loba a-brkt))
          ; current Mode in 'a-brkt'
          (define a-mode (breakout-mode a-brkt))
          ; updated Balls
          (define new-loba
            (map (lambda (a-ball)
                   (update-ball a-ball a-brkt))
                 a-loba)))
;    (cond
;      [(string=? a-mode "attract")
;       (update-attract a-brkt)]
;      [(string=? a-mode "ready-to-play")
;       (update-ready-to-play a-brkt)]
;      [(string=? a-mode "play")
;       (update-play a-brkt)]
       (make-breakout new-loba
                      (remove-bricks new-loba a-lobr)
                      (breakout-lop a-brkt)
                      (breakout-score a-brkt)
                      (breakout-high-score a-brkt)
                      (breakout-credit-count a-brkt)
                      (+ SPT (breakout-second-count a-brkt))
                      (breakout-ctrl-panel a-brkt)
                      (breakout-mode a-brkt))))

;(define (update-attract a-brkt)
;  (cond
;    [(cavity?)
;     (update-play-cavity a-brkt)]
;    [(double?)
;     (update-play-double a-brkt)]
;    [(progressive?)
;     (update-play-progressive a-brkt)]))
;
;(define (update-ready-to-play a-brkt)
;  (...))
;
;(define (update-play a-brkt)
;  (cond
;    [(cavity? (play-game a))
;     (update-play-cavity a-brkt)]
;    [(double? (play-game a))
;     (update-play-double a-brkt)]
;    [(progressive? (play-game a))
;     (update-play-progressive a-brkt)]))
  
; update-ball : Ball Breakout -> Ball
; update 'a-ball' for one clock tick given current Breakout 'a-brkt'
(define (update-ball a-ball a-brkt)
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
                          (ball-paddle-hit-count a-ball))]
              ; left sidewall collision
              [(<= x2 BALL-MIN-X)
               (make-ball BALL-MIN-X y2
                          (ball-speed a-ball)
                          (reflect-h (ball-dir a-ball))
                          (ball-last-vobject a-ball)
                          (ball-paddle-hit-count a-ball))]
              ; no collision
              [else
               (make-ball x2 y2
                          (ball-speed a-ball)
                          (ball-dir a-ball)
                          (ball-last-vobject a-ball)
                          (ball-paddle-hit-count a-ball))]))
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
                  (ball-paddle-hit-count new-ball))]
      ; backwall collision
      [(< y3 BALL-MIN-Y)
       (make-ball x3 y3
                  (ball-speed new-ball)
                  (reflect-v (ball-dir new-ball))
                  BACKWALL
                  (ball-paddle-hit-count new-ball))]
      ; brick collision
      [(not (false? collided-brick))
       (make-ball x3 y3
                  (ball-speed new-ball)
                  (reflect-v (ball-dir new-ball))
                  collided-brick
                  (ball-paddle-hit-count new-ball))]
      ; paddle collision
      [(not (false? collided-paddle))
       (make-ball x3 y3
                  (ball-speed new-ball)
                  (get-dir x3 collided-paddle)
                  collided-paddle
                  (add1 (ball-paddle-hit-count new-ball)))]
      ; no collision
      [else
       (make-ball x3 y3
                  (ball-speed new-ball)
                  (ball-dir new-ball)
                  (ball-last-vobject new-ball)
                  (ball-paddle-hit-count new-ball))])))

;;; Rendering
;;;;;;;;;;;;;;

; render : Breakout -> Breakout
; a rendered breakout game 'a-brkt'
(define (render a-brkt)
  (render-balls (breakout-loba a-brkt)
                (render-bricks (breakout-lobr a-brkt)
                               ;(render-paddles (breakout-lop a-brkt)
                                               (render-text
                                               PF-IMG))))
; render-text : Image -> Image
(define (render-text bg-img)
  (place-image (scale 3 (string->image "1 COIN  1 PLAYER"))
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
       (place-image (rectangle IBRICK-WIDTH
                               IBRICK-HEIGHT
                               "solid"
                               (row->color (brick-row a-brick)))
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
       (place-image (square (* 2 BALL-RADIUS)
                            "solid"
                            "white")
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
       (place-image (rectangle (- (paddle-width a-paddle) PF-SPACING)
                               IBRICK-HEIGHT
                               "solid"
                               (row->color (paddle-row a-paddle)))
                    (+ (paddle-x a-paddle)
                       (/ (paddle-width a-paddle) 2))
                    (+ (row->y (paddle-row a-paddle))
                       (/ IBRICK-HEIGHT 2))
                    (render-paddles (rest a-lop) bg-img)))]))

;(define (handle-key a-brkt key)
;  (cond
;    [(or (key=? " " key)
;         (key=? "\r" key))
;     (try-serve a-brkt)]
;    [(or (key=? "left" key)
;         (key=? "up" key)
;         (key=? "a" key)
;         (key=? "w" key))
;     (try-switch-left-game a-brkt)]
;    [(or (key=? "right" key)
;         (key=? "bottom" key)
;         (key=? "d" key)
;         (key=? "s" key))
;     (try-switch-right-game a-brkt)]
;    [(key=? "1" key)
;     (one-player a-brkt)]
;    [(key=? "2" key)
;     (two-player a-brkt)]))
;
;(define (handle-mouse a-brkt x y mouse)
;  (try-update-paddles x a-brkt))

;;; Main function
;;;;;;;;;;;;;;;;;;

; run : Breakout -> Breakout
; run the breakout game with initial state 'a-brkt0'
(define (run a-brkt0)
  (big-bang a-brkt0
    [on-tick update SPT]
    [state DEBUG?]
    [to-draw render]))

; List<Paddle>
(define LOP-0 (build-list (/ (- PF-COL-COUNT 2) 2)
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
(define LOBA-0 (list (make-ball (* PF-WIDTH 1/6) (row->y 22) 900 (/ pi 4) BACKWALL 0)
                     (make-ball (* PF-WIDTH 2/6) (row->y 22) 900 (/ pi 4) BACKWALL 0)
                     (make-ball (* PF-WIDTH 3/6) (row->y 22) 900 (/ pi 4) BACKWALL 0)
                     (make-ball (* PF-WIDTH 4/6) (row->y 22) 900 (/ pi 4) BACKWALL 0)
                     (make-ball (* PF-WIDTH 5/6) (row->y 22) 900 (/ pi 4) BACKWALL 0)))
; Breakout
(define BREAKOUT-0
  (make-breakout LOBA-0
                 LOBR-0
                 LOP-0
                 SCORE-0
                 HIGH-SCORE-0
                 CREDIT-COUNT-0
                 SECOND-COUNT-0
                 CTRL-PANEL-0
                 MODE-0))

(run BREAKOUT-0)
