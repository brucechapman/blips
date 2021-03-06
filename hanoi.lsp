(defun hanoi(cnt)
    (setq n cnt peg1 nil peg2 nil peg3 nil)
    (while (not (= n 0))
	(setq peg1 (cons n peg1) n (+ n -1))
    )
    (print (cons peg1 (cons peg2 (cons peg3 nil))))
    (move-stack cnt (quote peg1) (quote peg2) (quote peg3))
    (quote true)
)

(defun move-stack(cnt src dest wrk) 
    (if (not (= cnt 1))
	(move-stack (+ cnt -1) src wrk dest)
    )
    (move1 src dest)
    (if (not (= cnt 1))
	(move-stack (+ cnt -1) wrk dest src)
    )
)

(defun move1(src dest)
    (setq disk (car (eval src)))
    (set  dest (cons disk (eval dest)))
    (set src (cdr (eval src)))
    (print (cons peg1 (cons peg2 (cons peg3 nil))))
)

