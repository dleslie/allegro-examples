(use allegro lolevel)

(require-library allegro)
(import (prefix allegro al:))

(use allegro-glext allegro-c-util)

(define (abort x)
  (display x)
  (newline)
  (exit))

(define r 0.5)
(define g 0.5)
(define b 1)
(define ratio 0)
(define dir 1)

(define tinter-shader-source
  (list
   "uniform sampler2D backBuffer;"
   "uniform float r;"
   "uniform float g;"
   "uniform float b;"
   "uniform float ratio;"
   "void main() {"
   "	vec4 color;"
   "	float avg, dr, dg, db;"
   "	color = texture2D(backBuffer, gl_TexCoord[0].st);"
   "	avg = (color.r + color.g + color.b) / 3.0;"
   "	dr = avg * r;"
   "	dg = avg * g;"
   "	db = avg * b;"
   "	color.r = color.r - (ratio * (color.r - dr));"
   "	color.g = color.g - (ratio * (color.g - dg));"
   "	color.b = color.b - (ratio * (color.b - db));"
   "	gl_FragColor = color;"
   "}"))

(define tinter-length (length tinter-shader-source))

(if (not (al:init))
	(abort "Could not init Allegro"))

(al:init 'keyboard)
(al:init 'image)

(al:new-display-flags-set! (display-flag->int 'opengl))

(define main-display (al:make-display 320 200))

(if (not main-display)
	(abort "Error creating display"))

(define mysha (al:load-bitmap "data/mysha.pcx"))

(if (not mysha)
	(abort "Could not load image"))

(define buffer (al:make-bitmap 320 200))

(define tinter-shader (gl:CreateShader gl:FRAGMENT_SHADER))

(gl:ShaderSource tinter-shader tinter-length (make-c-string-list tinter-shader-source) #f)
(gl:CompileShader tinter-shader)
(define tinter (gl:CreateProgram))
(gl:AttachShader tinter tinter-shader)
(gl:LinkProgram tinter)
(define loc (gl:GetUniformLocation tinter "backBuffer"))
(gl:Uniform1i loc (al:opengl-texture buffer))

(define start (al:current-time))
(define kb-state (al:make-keyboard-state))

(letrec
	((loop
	  (lambda ()
		(keyboard-state-init! kb-state)
		(if (not (al:keyboard-state-key-down? kb-state 'escape))
			(begin
			  (define now (al:current-time))
			  (define diff (- now start))
			  (set! start now)
			  (set! ratio (+ ratio (* diff 0.5 dir)))
			  
			  (if (and (< dir 0) (< ratio 0))
				  (begin
					(set! ratio 1)
					(set! dir (- 0 dir)))
				  (if (and (> dir 0) (> ratio 1))
					  (begin
						(set! ratio 1)
						(set! dir (- 0 dir)))))

			  (al:target-bitmap-set! buffer)

			  (gl:UseProgram tinter)
			  (set! loc (gl:GetUniformLocation tinter "ratio"))
			  (gl:Uniform1f loc ratio)
			  (set! loc (gl:GetUniformLocation tinter "r"))
			  (gl:Uniform1f loc r)
			  (set! loc (gl:GetUniformLocation tinter "g"))
			  (gl:Uniform1f loc g)
			  (set! loc (gl:GetUniformLocation tinter "b"))
			  (gl:Uniform1f loc b)

			  (al:bitmap-draw mysha 0 0 0)

			  (gl:UseProgram 0)

			  (al:target-backbuffer-set! main-display)
			  (al:bitmap-draw buffer 0 0 0)
			  (al:flip-display)
			  (al:rest 0.001)

			  (loop))))))
  (loop))

(gl:DetachShader tinter tinter-shader)
(gl:DeleteShader tinter-shader)

(al:uninstall 'system)
