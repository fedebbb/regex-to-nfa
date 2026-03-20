;;; -*- Mode: Lisp -*-

;;; nfsa.lisp



;; Struttura automa.


(defstruct automa
  nfsa_init
  nfsa_final
  nfsa_delta
  nfsa_epsilon_transition)


;; is-regex.


(defun is-regex (RE)
  (cond ((atom RE) t)
	((member (car RE) '(z c a o))
	 (case (car RE)
	   ((a c)
	    (if (null (cdr RE))
		t
		(and (> (length (cdr RE)) 1)
		     (every #'is-regex (cdr RE)))))
	   ((o z)
	    (if (null (cdr RE))
		t
		(and (= (length (cdr RE)) 1)
		     (is-regex (car (cdr RE))))))))
	(t t)))


;; nfsa-compile-regex.


(defun nfsa-compile-regex (RE)
  (cond ((is-regex RE)
	 (nfsa_create RE))))


;; nfsa-create.

;; Creazione automa per la regex.


(defun nfsa_create (RE)
  (cond ((atom RE)
	 (let ((Start (gensym "q")) (Final (gensym "q")))
	   (make-automa
	    :nfsa_init Start
	    :nfsa_final Final
	    :nfsa_delta (list (list Start RE Final))
	    :nfsa_epsilon_transition nil)))
	((member (car RE) '(z c a o))
	 (case (car RE)
	   (c
	    (if (null (cdr RE))
		(create_epsilon_automa)
		(let ((Automi (nfsa_create_args (cdr RE))))
		  (make-automa
		   :nfsa_init (automa-nfsa_init (first Automi))
		   :nfsa_final (automa-nfsa_final (car (last Automi)))
		   :nfsa_delta (get_delta Automi)
		   :nfsa_epsilon_transition (append
					     (get_epsilon_conc Automi)
					     (get_epsilon_automi Automi))))))
	   (a
	    (if (null (cdr RE))
		(create_epsilon_automa)
		(let ((Automi (nfsa_create_args (cdr RE)))
		      (Start (gensym "q"))
		      (Final (gensym "q")))
		  (make-automa
		   :nfsa_init Start
		   :nfsa_final Final
		   :nfsa_delta (get_delta Automi)
		   :nfsa_epsilon_transition (append
					     (get_epsilon_alt
					      Automi
					      Start
					      Final)
					     (get_epsilon_automi
					      Automi))))))
	   (z
	    (if (null (cdr RE))
		(create_epsilon_automa)
		(let ((A (nfsa_create (cadr RE)))
		      (Start (gensym "q"))
		      (Final (gensym "q")))
		  (make-automa
		   :nfsa_init Start
		   :nfsa_final Final
		   :nfsa_delta (automa-nfsa_delta A)
		   :nfsa_epsilon_transition (append
					     (automa-nfsa_epsilon_transition
					      A)
					     (get_epsilon_kleene
					      A
					      Start
					      Final))))))
	   (o
	    (if (null (cdr RE))
		(create_epsilon_automa)
		(let ((A (nfsa_create (cadr RE)))
		      (Start (gensym "q"))
		      (Final (gensym "q")))
		  (make-automa
		   :nfsa_init Start
		   :nfsa_final Final
		   :nfsa_delta (automa-nfsa_delta A)
		   :nfsa_epsilon_transition (append
					     (automa-nfsa_epsilon_transition
					      A)
					     (get_epsilon_rip
					      A
					      Start
					      Final))))))))
	(t
	 (let ((Start (gensym "q")) (Final (gensym "q")))
	   (make-automa
	    :nfsa_init Start
	    :nfsa_final Final
	    :nfsa_delta (list (list Start RE Final))
	    :nfsa_epsilon_transition nil)))))


;; create_epsilon_automa.

;; Creazione automa per epsilon.

(defun create_epsilon_automa ()
  (let ((Start (gensym "q"))
	(Final (gensym "q")))
    (make-automa
     :nfsa_init Start
     :nfsa_final Final
     :nfsa_delta nil
     :nfsa_epsilon_transition (list (list Start Final)))))


;; nfsa_create_args.

;; Creazione automa per gli argomenti di c, a, o, z.


(defun nfsa_create_args (Args)
  (if (null Args)
      nil
      (cons (nfsa_create (car Args))
	    (nfsa_create_args (cdr Args)))))


;; get_delta.

;; Unione delle delta degli automi.


(defun get_delta (Lista)
  (if (null Lista)
      nil
      (append (automa-nfsa_delta (car Lista))
	      (get_delta (cdr Lista)))))


;; get_epsilon_conc.

;; Creazione espilon transizioni per concatenazione.


(defun get_epsilon_conc (Lista)
  (if (or (null Lista) (null (cdr Lista)))
      nil
      (append (list (list (automa-nfsa_final (car Lista))
			  (automa-nfsa_init (cadr Lista))))
	    (get_epsilon_conc (cdr Lista)))))


;; get_epsilon_alt.

;; Creazione epsilon transizioni per alternativa.


(defun get_epsilon_alt (Lista Start Final)
  (if (null Lista)
      nil
      (append (list (list Start
			  (automa-nfsa_init (car Lista))))
	      (list (list (automa-nfsa_final (car Lista))
			  Final))
	      (get_epsilon_alt (cdr Lista) Start Final))))


;; get_epsilon_kleene.

;; Creazione epsilon transizioni per chiusura di kleene.


(defun get_epsilon_kleene (Element Start Final)
  (if (null Element)
      nil
      (append (list (list Start
			  (automa-nfsa_init Element)))
	      (list (list (automa-nfsa_final Element)
			  Final))
	      (list (list Start
			  Final))
	      (list (list (automa-nfsa_final Element)
			  (automa-nfsa_init Element))))))


;; get_epsilon_rip

;; Creazione epsilon transizioni per ripetizione.


(defun get_epsilon_rip (Element Start Final)
  (if (null Element)
      nil
      (append (list (list Start
			  (automa-nfsa_init Element)))
	      (list (list (automa-nfsa_final Element)
			  Final))
	      (list (list (automa-nfsa_final Element)
			  (automa-nfsa_init Element))))))


;; get_epsilon_automi

;; Unione epsilon transizioni degli automi.


(defun get_epsilon_automi (Lista)
  (apply #'append (remove nil
			  (mapcar #'automa-nfsa_epsilon_transition Lista))))


;; nfsa-recognize.


(defun nfsa-recognize (FA Input)
  (cond
    ((not (automa-p FA))
     (error "~s non è un automa valido" FA))
    ((not (listp Input))
     nil)
    (t
     (let ((Start (automa-nfsa_init FA)))
       (accept FA Input (list Start))))))


;; accept

;; Verifica se automa accetta la stringa o no.


(defun accept (FA Input S)
  (let ((States (eclose FA S nil)))
    (cond
      ((null Input)
       (not (null (member (automa-nfsa_final FA) States))))
      (t
       (let ((NextStates (state_transition FA (car Input) States)))
	 (accept FA (cdr Input) NextStates))))))


;; eclose.

;; Costruzione eclose degli stati.


(defun eclose (FA S Visited)
  (cond
    ((null S) Visited)
    ((member (car S) Visited)
     (eclose FA (cdr S) Visited))
    (t
     (let ((NextEpsilonStates
	    (get_nextstate_epsilon
	     (automa-nfsa_epsilon_transition FA)
	     (car S))))
       (eclose FA
	       (append (cdr S) NextEpsilonStates)
	       (cons (car S) Visited))))))


;; state_transition

;; Transizione degli stati.


(defun state_transition (FA Element States)
  (cond
    ((null States) nil)
    (t
     (let ((NextState (get_nextstate
		       (automa-nfsa_delta FA)
		       Element
		       (car States))))
       (append (if NextState (list NextState) nil)
	       (state_transition FA Element (cdr States)))))))


;; get_nextstate_epsilon

;; Stati raggiungibili con epsilon transizione da State.


(defun get_nextstate_epsilon (Lista State)
  (cond
    ((null Lista) nil)
    ((eq State (first (car Lista)))
     (cons (second (car Lista))
	   (get_nextstate_epsilon (cdr Lista) State)))
    (t
     (get_nextstate_epsilon (cdr Lista) State))))


;; get_nextstate

;; Stato raggiungibile da State consumando un simbolo della stringa.


(defun get_nextstate (Lista Element State)
  (let ((delta (car Lista)))
    (cond
      ((null Lista) nil)
      ((and (eq State (first delta))
	    (equal Element (second delta)))
       (third delta))
      (t
       (get_nextstate (cdr Lista) Element State)))))
  

;;; nfsa.lisp ends here.





  


