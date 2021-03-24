#lang racket/base
(require racket/list)
(require racket/file)
(require racket/date)
(require racket/path)
(require racket/format)
(require racket/string)
(require racket/format)
(require racket/cmdline)
(require racket/gui/base)
(require scribble/html/xml)
(require scribble/html/html)
(require gregor)
(module+ test
  (require rackunit))

;;; purpose

; to generate an invoice, with a unique number, today's date, due date at a configurable interval

;;; features

; - keep track of different clients;
; - keep track of invoice numbers for each client;
; - allow for default amounts per client or item line, tax rate;
; - global idea of 'account'. Contains client information, payment method, tax rate and currency;

;;; usage

; create a folder with the following files:
; - payee.txt          - containing the company address;
; - payor.txt          - containing the client's address;
; - invoice-number.txt - containing the last current invoice number. Incremented automatically;
; - tax-rate.txt       - containing the tax rate (i.e. 13);
; - pay-interval.txt   - containing the pay interval (i.e. 30);
; - locale.txt         - containing the date locale (i.e. 'en');
; - branch-address.txt - containing the bank branch address;
; - account-info.txt   - containing the bank account information;
; - invoice-lines.txt  - containing the invoice lines.

;;; version history

; v1.0 - this version. Racket 8.0.10

;;; consts

; local app files
(define *appname*              "Invoicer")
(define *version*              "1.0")
(define *logo-file*            "logo.png")
(define *style-sheet-file*     "style.css")
(define *separator*            "|")

; invoice files
(define *account-info-file*   "account-info.txt")
(define *branch-address-file* "branch-address.txt")
(define *invoice-number-file* "invoice-number.txt")
(define *invoice-lines-file*  "invoice-lines.txt")
(define *locale-file*         "locale.txt")
(define *payee-file*          "payee.txt")
(define *payor-file*          "payor.txt")
(define *pay-interval-file*   "pay-interval.txt")
(define *tax-rate-file*       "tax-rate.txt")

; defaults
(define *default-tax-rate*     13)   ; 13 %
(define *default-locale*       "en") ; English
(define *default-pay-interval* 30)   ; 30 days

;;; defs

;; Macro that defines whichever parameters are fed to it and fills them in from command line
(define-syntax define-command-line-params
  (syntax-rules ()
    ((define-command-line-params appname param1 ...)
     (define-values (param1 ...)
       (command-line #:program appname
                     #:args (param1 ...)
                     (values param1 ...))))))

;; displays an error message and exits the application with error code 1
(define (die msg)
  (displayln msg)
  (exit 1))

;; returns a long-format formatted date string
;; locale is optionnal, and uses the specified default locale if not specified
(define (get-long-date-str date (locale *default-locale*))
  (parameterize ([current-locale locale])
    (~t date "MMMM d, y")))
; unit test
(module+ test
  (check-equal?
   (get-long-date-str (date 2022 01 02))
   "January 2, 2022"))

;; returns a formatted date string
;; locale is optionnal, and uses the specified default locale if not specified
(define (get-short-date-str date (locale *default-locale*))
  (parameterize ([current-locale locale])
    (~t date "dd/mm/y")))
; unit test
(module+ test
  (check-equal?
   (get-short-date-str (date 2022 03 19)) ; year month day
   "19/03/2020"))

;; returns a string concatenating the given lines, separated by HTML newlines
(define (concat lines)
  (literal (string-join lines "<br />")))
; unit test
(module+ test
  (check-equal?
   (xml->string (concat '("some" "cool" "lines")))
   "some<br />cool<br />lines"))

;; curried, generic procedure returns a two-items line block, given the class
;; if only one column, column is a list of two columns. Returns #f otherwise.
;; column1-or-lst can be a special XML object!
(define ((build-line class) column1-or-lst (column2 #f))
  (if column2
      (tr 'class: class
          (td column1-or-lst)
          (td column2))
      (if (list? column1-or-lst)
          (tr 'class: class
              (td (first  column1-or-lst))
              (td (second column1-or-lst)))
          #f)))

;; returns an HTML invoice, given the body contents
;; builds the body and returns it, given top, information tr's as well as item tr's.
(define (build-invoice invoice-title
                       style-sheet
                       top-block
                       information-block
                       payment-method-block
                       item-lines
                       tax-amount
                       total-amount)
  (xml->string
   (list
    (doctype 'html)
    (html
     (head
      (meta 'charset: "uft-8")
      (title invoice-title)
      ; embed print page script
      (script/inline 'type: "text/javascript" "window.print();")
      ; stylesheet
      (style/inline 'type: "text/css"
                    style-sheet))
     (body
      (div 'class: "invoice-box"
           (table 'cellpadding: "0" 'cellspacing: "0"
                  top-block
                  information-block
                  payment-method-block
                  ((build-line "heading") "Item" "Price")
                  (build-items item-lines)
                  ((build-line "HST") "" (string-append "Tax (HST): " tax-amount))
                  ((build-line "total") "" (string-append "Total: " total-amount)))))))))

;; returns the top block (logo on the left, invoice data (number + dates) on the right)
(define (build-top-block logo-file invoice-number creation-date due-date locale)
  (tr 'class: "top"
      (td 'colspan: "2"
          (table
           (tr
            (td 'class: "title"
                (img 'src: logo-file 'style: "width: 100%; max-width: 300px"))
            (td
             "Invoice #: " (~r invoice-number #:min-width 3 #:pad-string "0") (br)
             "Created:"    (get-long-date-str creation-date locale) (br)
             "Due: "       (get-long-date-str due-date locale)))))))

;; returns the information block (addresses for payee on the left and payor on the right)
(define (build-information-block payee-address-lines payor-address-lines)
  (tr 'class: "information"
      (td 'colspan: "2"
          (table
           (tr
            (td (concat payee-address-lines))
            (td (concat payor-address-lines)))))))

;; returns a payment method block
;; types: 'check 'transfert
(define (build-payment-method-block type check-number account-info-lines branch-address-lines)
  (case type
    ((check)     (list ((build-line "heading") "Payment Method" "Check #")
                       ((build-line "details") "Check" check-number)))
    ((transfert) (list ((build-line "heading") "Account Information" "Branch Address")
                       ((build-line "details") (concat account-info-lines) (concat branch-address-lines))))))

;; returns item blocks, handles the last one correctly
(define (build-items lines)
  ; if only one line, return last line:
  (if (= (length lines) 1)
      ((build-line "item last")
       (first (first lines))
       (second (first lines)))
      ; else build lines and add special last.
      (list (map (build-line "item")   ; takes a list of two columns as param. 
                 (drop-right lines 1)) ; map takes a list of list of two columns
            ((build-line "item last")
             (first (last lines))
             (second (last lines))))))

;; returns taxes and total
(define (get-amounts item-lines (tax-rate *default-tax-rate*))
  (define (rotate lst)
    (apply map list lst))

  (define prices-str
    (second (rotate item-lines)))

  (define formatted-prices-str
    (map (λ (s) (string-replace s "," ".")) prices-str))

  (define prices
    (filter number?
            (map string->number formatted-prices-str)))

  (define total
    (apply + prices))

  (define tax
    (* total (/ tax-rate 100)))
    
  (values tax total))

;; returns a number contained in a file if it exists, #f otherwise
(define (file->number? file)
  (if (file-exists? file)
      (string->number (file->string file))
      (die (string-append "Missing " file ". Exiting."))))

;; returns a string contained in a file if it exists, #f otherwise
(define (file->string? file)
  (if (file-exists? file)
      (file->string file)
      (die (string-append "Missing " file ". Exiting."))))

;; returns a list of lines contained in a file if it exists, #f otherwise
(define (file->lines? file)
  (if (file-exists? file)
      (file->lines file)
      (die (string-append "Missing " file ". Exiting."))))

;; returns a list of lists of lines in a file if it exists, #f otherwise
(define (file->lines*? file)
  (if (file-exists? file)
      (map (λ (l) (string-split l *separator*)) (file->lines file))
      (die (string-append "Missing " file ". Exiting."))))

;; write an HTML invoice file given the invoice number
(define (write-invoice filename invoice-content invoice-number)
  (display-to-file invoice-content filename #:exists 'replace))

;; write an invoice-number file given the current invoice number
(define (update-invoice-number-file invoice-number)
  (display-to-file (number->string invoice-number)
                   *invoice-number-file*
                   #:exists 'replace))

;;; main

(define invoice-folder #f)

; gather command line parameters
(define args
  (vector->list (current-command-line-arguments)))

; if invoice folder found on the command line, get it
; open folder dialog otherwise.
(if (> (length args) 0)
    (set! invoice-folder (first args))
    (set! invoice-folder (get-directory)))

(unless invoice-folder
  (die "No invoice folder specified. Exiting."))

; check for style sheet file
(unless (file-exists? *style-sheet-file*)
  (die "Style sheet file not found. Exiting."))

; read style sheet
(define style-sheet
  (file->string *style-sheet-file*))

; check style sheet
(unless (non-empty-string? style-sheet)
  (die "Empty style sheet file!"))

; set working directory to specified invoice folder
(current-directory invoice-folder)

; read invoice files
(define account-info-lines   (file->lines?  *account-info-file*))
(define branch-address-lines (file->lines?  *branch-address-file*))
(define payee-address-lines  (file->lines?  *payee-file*))
(define payor-address-lines  (file->lines?  *payor-file*))
(define invoice-number       (file->number? *invoice-number-file*))
(define pay-interval         (file->number? *pay-interval-file*))
(define tax-rate             (file->number? *tax-rate-file*))
(define locale               (file->string? *locale-file*))
(define invoice-lines        (file->lines*? *invoice-lines-file*))

; set some sensible defaults if files aren't all found
(unless invoice-number (set! invoice-number 1))
(unless pay-interval   (set! tax-rate *default-pay-interval*))

; check information validity
(unless (> (length payor-address-lines) 0)
  (die "Invalid payor address. Exiting."))
(unless (> (length payee-address-lines) 0)
  (die "Invalid payee address. Exiting."))
(unless (> (length branch-address-lines) 0)
  (die "Invalid bank branch address. Exiting."))
(unless (> (length account-info-lines) 0)
  (die "Invalid bank account information. Exiting."))

; if no logo found in the invoice folder, use default from executable folder
(define logo-file-path *logo-file*)
(unless (file-exists? logo-file-path)
  (set! logo-file-path
        (build-path (path-only (find-system-path 'run-file)) *logo-file*)))
(unless (file-exists? logo-file-path)
  (die (string-append "Missing " *logo-file* ". Exiting.")))

; initialize date and due date
(define creation-date  (now))
(define due-date       (+days creation-date pay-interval))

; generate top block from given data
(define top-block
  (build-top-block logo-file-path invoice-number creation-date due-date locale))

; generate information block from given data
(define information-block
  (build-information-block payee-address-lines payor-address-lines))

; generate payment method block from given data
(define payment-method-block
  (build-payment-method-block 'transfert 001 account-info-lines branch-address-lines))

; calculate taxes and total
(define-values (tax-amount total-amount)
  (get-amounts invoice-lines tax-rate))

; grab payor name (company name?)
(define payor-name
  (first payor-address-lines))

; generate invoice title / filename
(define invoice-title
  (string-append (~r invoice-number #:min-width 3 #:pad-string "0")  ; 076
                 " - "                                               ;  - 
                 (get-short-date-str creation-date locale) ; 19/03/2020
                 " - "                                               ;  - 
                 payor-name))                                        ; Autospeed AutoParts Inc

; generate invoice HTML
(define invoice-content
  (build-invoice invoice-title
                 style-sheet
                 top-block
                 information-block
                 payment-method-block
                 invoice-lines
                 (string-append "$" (~r tax-amount   #:precision '(= 2)))
                 (string-append "$" (~r total-amount #:precision '(= 2)))))

; generate invoice filename
(define invoice-filename
  (string-append (string-replace invoice-title "/" "_") ".html"))

; write HTML invoice file
(write-invoice invoice-filename invoice-content invoice-number)

; update and write invoice number
(set! invoice-number (+ 1 invoice-number))
(update-invoice-number-file invoice-number)

; open resulting invoice in the browser
(void (shell-execute #f invoice-filename "" (current-directory) 'sw_shownormal))


; EOF
