;; A simple Hello World application
(require-library allegro)
(import (prefix allegro al:))

;; Print an error and quit the program
(define (error-quit x)
  (print x)
  (exit 1))

;; A record storing data required to draw a scene
(define-record scene width height font fgcolor bgcolor)

;; Draw a hello world scene
(define (draw-hello-scene scene)
  (al:clear-to-color (scene-bgcolor scene))
  (al:font-draw-string (scene-font scene) (scene-fgcolor scene)
		                   (/ (scene-width scene) 2)
		                   (/ (scene-height scene) 2)
		                   'center "Hello World")
  (al:flip-display))

;; Main function
(define (main)
  ;; Initialize the Allegro library
  (if (not (al:init))
      (error-quit "Could not initialize Allegro"))

  ;; Initialize some addons
  (al:init-this '(keyboard font ttf))

  ;; Create a display
  (al:new-display-flags-set! (al:combine-flags al:display-flag->int '(windowed resizable)))
  (define main-display (al:make-display 640 480))
  (if (not main-display)
      (error-quit "Unable to create display"))

  ;; Add an event queue for window events
  (define event-queue (al:make-event-queue))
  (al:event-queue-register-source! event-queue (al:display-event-source main-display))

  ;; Load a font for text rendering
  (define hello-font (al:load-ttf "data/DejaVuSans.ttf" 18 0))
  (if (not hello-font)
      (error-quit "Unable to load hello font"))

  ;; Some draw settings to use for the hello world scene
  (define hello-scene (make-scene 640 480 hello-font
				                          (al:make-color-name "black")
				                          (al:make-color-name "white")))

  ;; Start our main event loop via call/cc so we can exit cleanly
  (call/cc (lambda (quit)
             ;; A record to store event data in
             (let ([event (al:make-event)])
	             (let main-loop ()
	               ;; Draw the scene on every loop
	               (draw-hello-scene hello-scene)

	               ;; Grab and handle events
	               (if (al:event-queue-timed-wait! event-queue event 0.06)
	                   (case (al:event-type event)
		                   ((display-close) (quit 0))))

	               ;; Repeat
	               (main-loop))))))

;; Startup
(main)
