(import (prefix allegro al:)
        allegro-opengl)

(define tinter-shader-source
  "
uniform sampler2D backBuffer;
uniform float r;
uniform float g;
uniform float b;
uniform float ratio;
void main() {
	vec4 color;
	float avg, dr, dg, db;
	color = texture2D(backBuffer, gl_TexCoord[0].st);
	avg = (color.r + color.g + color.b) / 3.0;
	dr = avg * r;
	dg = avg * g;
	db = avg * b;
	color.r = color.r - (ratio * (color.r - dr));
	color.g = color.g - (ratio * (color.g - dg));
	color.b = color.b - (ratio * (color.b - db));
	gl_FragColor = color;
}
")

(define tinter-shader-cptr (al:make-c-string-list tinter-shader-source))

(define (main)
  (define (abort x)
    (display x)
    (newline)
    (quit 1))

  (when (not (al:init))
    (abort "Could not init Allegro"))

  (when (not (al:init))
    (abort "Could not init Allegro"))

  (al:init-this '(keyboard image))

  (al:new-display-flags-set! (al:display-flag->int 'opengl))
  (define main-display (al:make-display 320 200))
  (when (not main-display)
    (abort "Error creating display"))

  (define event-queue (al:make-event-queue))
  (al:event-queue-register-source! event-queue (al:display-event-source main-display))

  (define mysha (al:load-bitmap "data/mysha.pcx"))
  (when (not mysha)
    (abort "Could not load image"))

  (define buffer (al:make-bitmap 320 200))
  (when (or (not buffer)
	          (not (al:opengl-texture buffer)))
    (abort "Could not create render buffer"))

  (when (not (or (al:opengl-extension-exists? "GL_EXT_framebuffer_object")
                 (al:opengl-extension-exists? "GL_ARB_fragment_shader")))
    (abort "Fragment shaders are not supported."))

  (define tinter-shader (gl:create-shader-object-arb gl:fragment-shader-arb))
  (gl:shader-source-arb tinter-shader 1 tinter-shader-cptr #f)
  (gl:compile-shader-arb tinter-shader)

  (define tinter (gl:create-program-object-arb))
  (gl:attach-object-arb tinter tinter-shader)
  (gl:link-program-arb tinter)

  (let ((loc (gl:get-uniform-location-arb tinter "backBuffer")))
    (gl:uniform1i-arb loc (al:opengl-texture buffer)))

  (define r 0)
  (define g 0)
  (define b 0)
  (define ratio 0)
  (define dir 1)
  (define start (al:current-time))
  (define kb-state (al:make-keyboard-state))

  (define (render)
    (define now (al:current-time))
    (define diff (- now start))
    (set! start now)
    (set! ratio (+ ratio (* diff 0.5 dir)))

    (if (and (< dir 0) (< ratio 0))
        (begin
	        (set! ratio 0)
	        (set! dir (- 0 dir)))
        (if (and (> dir 0) (> ratio 1))
	          (begin
	            (set! ratio 1)
	            (set! dir (- 0 dir)))))

    (al:target-bitmap-set! buffer)

    (gl:use-program-object-arb tinter)
    (let ((loc (gl:get-uniform-location-arb tinter "ratio")))
      (gl:uniform1f-arb loc ratio))
    (let ((loc (gl:get-uniform-location-arb tinter "r")))
      (gl:uniform1f-arb loc r))
    (let ((loc (gl:get-uniform-location-arb tinter "g")))
      (gl:uniform1f-arb loc g))
    (let ((loc (gl:get-uniform-location-arb tinter "b")))
      (gl:uniform1f-arb loc b))
    (al:bitmap-draw mysha 0 0 0)
    (gl:use-program-object-arb 0)

    (al:target-backbuffer-set! main-display)
    (al:bitmap-draw buffer 0 0 0)
    (al:flip-display)
    (al:rest 0.001))

  (call/cc
   (lambda (quit)
     (let ([event (al:make-event)])
       (let loop ()
         (if (al:event-queue-timed-wait! event-queue event 0.06)
	           (case (al:event-type event)
		           ((display-close) (quit 0))))

         (al:keyboard-state-init! kb-state)
         (when (al:keyboard-state-key-down? kb-state 'escape)
           (quit 0))

         (render)

         (loop)))

     (quit 0)))

  (gl:detach-object-arb tinter tinter-shader)
  (gl:delete-object-arb tinter-shader))

(main)
