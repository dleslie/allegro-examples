(use (prefix allegro al:)
     (prefix opengl-glew gl:)
     (prefix gl-utils gl:))

(define (abort x)
  (display x)
  (newline)
  (exit))

(if (not (al:init))
    (abort "Could not init Allegro"))

(al:init 'keyboard)
(al:init 'image)

(al:new-display-flags-set! (al:display-flag->int 'opengl))
(define main-display (al:make-display 320 200))
(if (not main-display)
    (abort "Error creating display"))

(gl:init)

(define mysha (al:load-bitmap "data/mysha.pcx"))
(if (not mysha)
    (abort "Could not load image"))

(al:new-bitmap-flags-set! (al:bitmap-flag->int 'video-bitmap))
(define buffer (al:make-bitmap 320 200))
(if (or (not buffer)
	(not (al:opengl-texture buffer)))
    (abort "Could not create render buffer"))

(define tinter-shader-source "
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
(define tinter-shader (gl:make-shader gl:+fragment-shader+ tinter-shader-source))
(define shader-program (make-parameter (gl:make-program `(,tinter-shader))))
  
(gl:uniform1i (gl:get-uniform-location (shader-program) "backBuffer")
	      (al:opengl-texture buffer))

(define r 0.5)
(define g 0.5)
(define b 1)
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

  ;; (gl:clear (bitwise-ior gl:+color-buffer-bit+ gl:+depth-buffer-bit+))
  
  (al:target-bitmap-set! buffer)

  (gl:use-program (shader-program))
  (gl:uniform1f (gl:get-uniform-location (shader-program) "r") r)
  (gl:uniform1f (gl:get-uniform-location (shader-program) "g") g)
  (gl:uniform1f (gl:get-uniform-location (shader-program) "b") b)
  (gl:uniform1f (gl:get-uniform-location (shader-program) "ratio") ratio)
  (al:bitmap-draw mysha 0 0 0)
  (gl:use-program 0)

  (al:target-backbuffer-set! main-display)

  (al:bitmap-draw buffer 0 0 0)
  (al:flip-display)
  (al:rest 0.001))

(let loop ()
  (al:keyboard-state-init! kb-state)
  (when (not (al:keyboard-state-key-down? kb-state 'escape))
    (render)
    (loop)))
