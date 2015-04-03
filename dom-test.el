(require 'dom)

(when (file-readable-p "sample.xml")
  (message "Running tests")
  (let ((data (with-temp-buffer
                (insert-file-contents "sample.xml")
                (libxml-parse-xml-region (point-min) (point-max)))))
    
    (cl-assert (fboundp 'dom-node-name))
    (cl-assert (fboundp 'dom-document-name))
    (cl-assert (fboundp 'dom-element-name))
    (cl-assert (fboundp 'dom-attr-name))

    (let ((attr (dom-make-attribute-from-xml
                 (car (xml-node-attributes data)) 'none 'none)))
      (cl-assert (string= "id" (dom-node-name attr)))
      (cl-assert (string= "compiler" (dom-node-value attr)))
      (cl-assert (eq dom-attribute-node (dom-node-type attr))))

    (let ((element (dom-make-node-from-xml data 'no-owner)))
      (cl-assert (string= "book" (dom-node-name element)))
      (cl-assert (string= "id" (dom-node-name
                                (car (dom-node-attributes element)))))
      (cl-assert (string= "compiler"
                          (dom-node-value
                           (car (dom-node-attributes element)))))
      (cl-assert (string= "bookinfo"
                          (dom-node-name 
                           (first (dom-node-child-nodes element)))))
      (cl-assert (string= "chapter"
                          (dom-node-name
                           (second (dom-node-child-nodes element)))))
      (let ((title (first
                    (dom-node-child-nodes
                     (first
                      (dom-node-child-nodes
                       (first
                        (dom-node-child-nodes element))))))))
        (cl-assert (eq 'title (dom-node-name title)))
        (cl-assert (string= "My own book!"
                            (dom-node-value
                             (first (dom-node-child-nodes title)))))))

    (let ((doc (dom-make-document-from-xml data)))
      (cl-assert (eq dom-document-node-name (dom-document-name doc)))
      (cl-assert (string= "book" (dom-node-name (dom-document-element doc))))
      (cl-assert (eq (dom-node-parent-node
                      (first (dom-node-child-nodes (dom-document-element doc))))
                     (dom-document-element doc)))
      (cl-assert (eq (first (dom-node-child-nodes (dom-document-element doc)))
                     (dom-node-first-child (dom-document-element doc))))
      (cl-assert (eq (dom-node-next-sibling
                      (first (dom-node-child-nodes (dom-document-element doc))))
                     (second (dom-node-child-nodes (dom-document-element doc)))))
      (cl-assert (eq doc
                     (dom-node-owner-document
                      (dom-node-first-child (dom-document-element doc)))))
      (cl-assert (string= "chapter"
                          (dom-node-name
                           (dom-element-last-child
                            (dom-document-element doc)))))
      (cl-assert (eq nil (dom-node-previous-sibling (dom-document-element doc)))))

    (cl-assert (eq 3 (dom-node-list-length '(1 2 3))))

    (cl-assert (eq 2 (dom-node-list-item '(1 2 3) 1)))

    (let ((doc (dom-make-document-from-xml data)))
      (cl-assert (equal (mapcar 'dom-node-name
                                (dom-document-get-elements-by-tag-name
                                 doc '*))
                        '(book bookinfo bookbiblio title \#text edition
                               \#text authorgroup author firstname \#text
                               surname \#text chapter title \#text para
                               \#text)))
      (cl-assert (equal (mapcar 'dom-node-name
                                (dom-document-get-elements-by-tag-name
                                 doc 'title))
                        '(title title)))
      (cl-assert (equal (mapcar 'dom-node-name
                                (dom-element-get-elements-by-tag-name
                                 (dom-document-element doc) 'title))
                        '(title title)))
      (cl-assert (equal (mapcar (lambda (element)
                                  (dom-node-value
                                   (dom-element-first-child element)))
                                (dom-document-get-elements-by-tag-name
                                 doc 'title))
                        '("My own book!" "A very small chapter"))))

    (let* ((doc (dom-make-document-from-xml data))
           (ancestor (dom-document-element doc))
           (child (car (dom-document-get-elements-by-tag-name doc 'title))))
      (cl-assert (dom-node-ancestor-p child ancestor)))

    (let* ((doc (dom-make-document-from-xml data))
           (book (dom-document-element doc))
           (old-chapter (dom-element-last-child book))
           (new-chapter (dom-document-create-element doc 'chapter)))
      (cl-assert (string= (dom-node-name
                           (dom-element-append-child book new-chapter))
                          "chapter"))
      (cl-assert (equal (mapcar 'dom-element-name
                                (dom-element-child-nodes book))
                        '(bookinfo chapter chapter)))
      (cl-assert (eq (dom-element-last-child book) new-chapter))
      (cl-assert (not (eq (dom-element-last-child book) old-chapter)))
      (cl-assert (eq (dom-element-next-sibling old-chapter) new-chapter))
      (cl-assert (eq (dom-element-previous-sibling new-chapter) old-chapter))
      (cl-assert (eq (dom-element-parent-node new-chapter) book))
      (cl-assert (dom-node-ancestor-p new-chapter book))
      (cl-assert (not (eq t (condition-case var
                                (dom-element-append-child book new-chapter)
                              ('dom-hierarchy-request-err
                               t)))))
      (cl-assert (eq t (condition-case var
                           (dom-element-append-child new-chapter book)
                         ('dom-hierarchy-request-err
                          t)))))

    (let* ((doc (dom-make-document-from-xml data))
           (book (dom-document-element doc))
           (old-chapter (dom-element-last-child book))
           (new-chapter (dom-document-create-element doc 'chapter))
           (new-title (dom-document-create-element doc 'title))
           (text (dom-document-create-text-node doc "Test Chapter")))
      (cl-assert (eq text (dom-element-append-child
                           (dom-element-append-child
                            (dom-element-append-child book new-chapter)
                            new-title)
                           text)))
      (cl-assert (= 2 (length (dom-node-child-nodes old-chapter))))
      (cl-assert (= 1 (length (dom-node-child-nodes new-chapter))))
      (cl-assert (string= "title" (dom-node-name
                                   (car (dom-node-child-nodes new-chapter)))))
      (cl-assert (eq (car (dom-node-child-nodes new-chapter))
                     (dom-node-first-child new-chapter)))
      (cl-assert (eq new-title
                     (dom-node-first-child new-chapter)))
      (cl-assert (eq text
                     (dom-node-first-child new-title)))
      (cl-assert (equal
                  (mapcar (lambda (node)
                            (dom-node-value
                             (dom-node-first-child node)))
                          (dom-document-get-elements-by-tag-name doc 'title))
                  '("My own book!" "A very small chapter" "Test Chapter"))))

    (let* ((doc (dom-make-document-from-xml data))
           (book (dom-document-element doc))
           (copy (dom-node-clone-node book)))
      (cl-assert (not (eq book copy)))
      (cl-assert (eq (dom-node-child-nodes book)
                     (dom-node-child-nodes copy)))
      (cl-assert (eq (car (dom-node-child-nodes book))
                     (car (dom-node-child-nodes copy))))
      (cl-assert (eq (dom-node-first-child book)
                     (dom-node-first-child copy)))
      (cl-assert (eq (dom-node-last-child book)
                     (dom-node-last-child copy)))
      (cl-assert (not (eq (dom-node-attributes book)
                          (dom-node-attributes copy))))
      (cl-assert (eq (dom-node-name (car (dom-node-attributes book)))
                     (dom-node-name (car (dom-node-attributes copy)))))
      (cl-assert (not (eq (dom-node-value (car (dom-node-attributes book)))
                          (dom-node-value (car (dom-node-attributes copy))))))
      (cl-assert (equal (dom-node-value (car (dom-node-attributes book)))
                        (dom-node-value (car (dom-node-attributes copy))))))

    (let* ((doc (dom-make-document-from-xml data))
           (book (dom-document-element doc))
           (deepcopy (dom-node-clone-node book t)))
      (cl-assert (not (eq book deepcopy)))
      (cl-assert (equal (dom-node-attributes book)
                        (dom-node-attributes deepcopy)))
      (cl-assert (not (eq (dom-node-attributes book)
                          (dom-node-attributes deepcopy))))
      (cl-assert (equal
                  (mapcar 'dom-node-name
                          (dom-element-get-elements-by-tag-name book '*))
                  (mapcar 'dom-node-name
                          (dom-element-get-elements-by-tag-name deepcopy '*))))
      (cl-assert (equal
                  (mapcar 'dom-node-value
                          (dom-element-get-elements-by-tag-name book '*))
                  (mapcar 'dom-node-value
                          (dom-element-get-elements-by-tag-name deepcopy '*))))
      (cl-assert (not (eq (car (dom-element-get-elements-by-tag-name
                                book 'firstname))
                          (car (dom-element-get-elements-by-tag-name
                                deepcopy 'firstname)))))
      (cl-assert (not (eq (dom-text-value
                           (third (dom-element-get-elements-by-tag-name
                                   book '\#text)))
                          (dom-text-value
                           (third (dom-element-get-elements-by-tag-name
                                   deepcopy '\#text))))))
      (cl-assert (string= (dom-text-value
                           (third (dom-element-get-elements-by-tag-name
                                   book '\#text)))
                          (dom-text-value
                           (third (dom-element-get-elements-by-tag-name
                                   deepcopy '\#text)))))
      (cl-assert (not (eq (dom-text-value
                           (third (dom-element-get-elements-by-tag-name
                                   book '\#text)))
                          (dom-text-value
                           (third (dom-element-get-elements-by-tag-name
                                   deepcopy '\#text)))))))
    
    (let* ((doc (dom-make-document-from-xml data))
           (book (dom-document-element doc))
           (old-chapter (dom-element-last-child book))
           (new-chapter (dom-document-create-element doc 'chapter)))
      (cl-assert (eq (dom-node-name (dom-element-insert-before book new-chapter))
                     'chapter))
      (cl-assert (equal (mapcar 'dom-element-name
                                (dom-element-child-nodes book))
                        '(bookinfo chapter chapter)))
      (cl-assert (eq new-chapter (dom-element-insert-before 
                                  book new-chapter
                                  (dom-element-first-child book))))
      (cl-assert (equal (mapcar 'dom-element-name
                                (dom-element-child-nodes book))
                        '(chapter bookinfo chapter)))
      (let ((new-bookinfo (dom-document-create-element doc 'bookinfo)))
        (dom-element-insert-before book new-bookinfo old-chapter))
      (cl-assert (equal (mapcar 'dom-element-name
                                (dom-element-child-nodes book))
                        '(chapter bookinfo bookinfo chapter))))

    ;; FIXME: some more tests for `dom-node-remove-child' and
    ;; `dom-node-replace-child' would be nice...  :)
    (let* ((doc (dom-make-document-from-xml data))
           (book (dom-document-element doc))
           (old-chapter (dom-element-last-child book))
           (new-chapter (dom-document-create-element doc 'chapter)))
      (dom-node-remove-child book old-chapter)
      (cl-assert (equal (mapcar 'dom-node-name (dom-node-child-nodes book))
                        '(bookinfo)))
      (dom-node-replace-child book new-chapter
                              (dom-node-first-child book))
      (cl-assert (equal (mapcar 'dom-node-name (dom-node-child-nodes book))
                        '(chapter))))

    (let* ((doc (make-dom-document))
           (par (dom-document-create-element doc 'p))
           (part1 (dom-document-create-text-node doc "This is "))
           (part2 (dom-document-create-element doc 'b))
           (part3 (dom-document-create-text-node doc ".")))
      (dom-element-append-child 
       part2 (dom-document-create-text-node doc "bold"))
      (dom-element-append-child par part1)
      (dom-element-append-child par part2)
      (dom-element-append-child par part3)
      (setf (dom-document-owner-document doc) doc
            (dom-document-element doc) par)
      (cl-assert (eq (dom-document-element doc) par))
      (cl-assert (string= (dom-node-text-content par)
                          "This is bold."))
      (dom-node-set-text-content par "This is plain.")
      (cl-assert (string= (dom-node-text-content par)
                          "This is plain."))
      (cl-assert (equal (mapcar 'dom-node-name (dom-node-child-nodes par))
                        '(\#text)))
      (dom-node-set-text-content par "New text.")
      (cl-assert (string= (dom-node-text-content par)
                          "New text."))
      (dom-node-set-text-content par "Different text.")
      (cl-assert (string= (dom-element-text-content par)
                          "Different text."))
      (let ((at (dom-document-create-attribute doc 'foo)))
        (setf (dom-attr-value at) "domino"
              (dom-element-attributes par) (list at))
        (cl-assert (string= "domino"
                            (dom-node-value
                             (dom-node-list-item
                              (dom-element-attributes par)
                              0))))
        (cl-assert (string= "domino"
                            (dom-node-text-content
                             (dom-node-list-item
                              (dom-element-attributes par)
                              0))))))

    (let* ((doc (dom-make-document-from-xml data))
           (title (car (dom-document-get-elements-by-tag-name doc "title"))))
      (cl-assert (equal (dom-element-text-content title)
                        "My own book!"))))
  (message "Passed tests!"))
