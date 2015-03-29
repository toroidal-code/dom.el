# dom.el #

Pure emacs-lisp DOM manipulation at its finest

Credit Where It's Due:
----------------------

This code was originally developed by Alex Schroder and then improved
by Henrik Motakef. So far, the only thing I have done is
update it to the bare-minimum working requirements for
this decade's version of Emacs.

Overview
--------

If you are working with XML documents, the parsed data structure
returned by the XML parser (xml.el) may be enough for you: Lists of
lists, symbols, strings, plus a number of accessor functions.

If you want a more elaborate data structure to work with your XML
document, you can create a document object model (DOM) from the XML
data structure using dom.el.

You can create a DOM from XML using `dom-make-document-from-xml`
with the input from `libxml-parse-xml-region`. See function documentation
below for an example

### On Interfaces and Classes ###

This elisp DOM implementation uses the dom-node structure to store all
attributes. The various interfaces consist of sets of functions to
manipulate these dom-nodes. The functions of a certain interface
share the same prefix.


Function Documentation
----------------------

### DOMException ###


DOM operations only raise exceptions in "exceptional" circumstances,
i.e., when an operation is impossible to perform (either for logical
reasons, because data is lost, or because the implementation has
become unstable). In general, DOM methods return specific error
values in ordinary processing situations, such as out-of-bound errors
when using a list of nodes.

##### `(dom-exception EXCEPTION &rest DATA)` ####

Signal error EXCEPTION, possibly providing DATA.
The error signaled has the condition 'dom-exception in addition
to the catch-all 'error and EXCEPTION itself.

### Document Interface ###

The Document interface represents the entire HTML or XML document.
Conceptually, it is the root of the document tree, and provides the
primary access to the document's data.

Since elements, text nodes, comments, processing instructions, etc.
cannot exist outside the context of a Document, the Document interface
also contains the factory methods needed to create these objects. The
Node objects created have a ownerDocument attribute which associates
them with the Document within whose context they were created.

It should also be noted that the Document interface has accessors
directly derived from the Node interface, only with the prefix
`dom-document` instead of `dom node`. There is also an added field
`element` which denotes the root element of the document.

#### Constructor

##### `(dom-make-document-from-xml NODE)` ####

Return a DOM document based on NODE.
NODE is a node as returned by `libxml-parse-xml-region`.
The DOM nodes are created using `dom-make-node-from-xml`.

Example:
```elisp
(let ((doc (dom-make-document-from-xml 
           (with-temp-buffer
             (insert-file-contents "sample.xml")
             (libxml-parse-xml-region 
               (point-min) (point-max))))))
   (some-dom-thing-here doc))
```

### Other Document functions

##### `(dom-document-create-attribute DOC NAME)` ####

Create an attribute of the given NAME.
DOC is the owner-document. Note that the Attr instance can
then be set on an Element using the setAttributeNode method.

##### `(dom-document-create-element DOC TYPE)` ####

Create an element of the given TYPE.
TYPE will be interned, if it is a string.
DOC is the owner-document.

Note that the instance
returned implements the Element interface, so attributes can be
specified directly on the returned object.

##### `(dom-document-create-text-node DOC DATA)` ####

Create a text element containing DATA.
DOC is the owner-document.

##### `(dom-document-get-elements-by-tag-name DOC TAGNAME)` ####

Return a list of all the elements with the given tagname.
The elements are returned in the order in which they are encountered in
a preorder traversal of the document tree.  The special value "*"
matches all tags.


### Node Interface ###

Node is the primary datatype for the entire Document
Object Model. It represents a single node in the document tree. While
all objects implementing the Node interface expose methods for dealing
with children, not all objects implementing the Node interface may have
children. For example, Text nodes may not have children, and adding
children to such nodes results in a DOMException being raised.

The attributes name, value and attributes are included as a mechanism
to get at node information without casting down to the specific
derived interface. In cases where there is no obvious mapping of
these attributes for a specific type (e.g., value for an Element or
attributes for a Comment), this returns null. Note that the
specialized interfaces may contain additional and more convenient
mechanisms to get and set the relevant information.

All functions defined for nodes are defined for documents,
elements, and attributes as well.

#### Constructor

##### `(dom-make-node-from-xml NODE OWNER)` ####

Make a DOM node based on NODE.
If NODE is a list, the node is created by `dom-make-element-from-xml`.
OWNER is stored as the owner-document.

#### Accessors

##### `(dom-node-name NODE)`

##### `(dom-node-value NODE)`

##### `(dom-node-type NODE)`

##### `(dom-node-parent-nodes NODE)`

##### `(dom-node-child-nodes NODE)`

##### `(dom-node-attributes NODE)`

##### `(dom-node-owner-document NODE)`


#### Additional traversal functions

##### `(dom-node-first-child NODE)`

##### `(dom-node-last-child NODE)`

##### `(dom-node-previous-sibling NODE)`

##### `(dom-node-next-sibling NODE)`

#### Functions acting on the child nodes list

##### `(dom-add-children PARENT CHILDREN)` ####

Add CHILDREN to PARENT.
CHILDREN is a list of XML NODE elements.  Each must
be converted to a dom-node first.

##### `(dom-node-append-child NODE NEW-CHILD)` ####

Adds NEW-CHILD to the end of the list of children of NODE.
If NEW-CHILD is already in the document tree, it is first removed.
NEW-CHILD will be removed from anywhere in the document!
Return the node added.

##### `(dom-node-clone-node NODE &optional DEEP)` ####

Return a duplicate of NODE.
The duplicate node has no parent.  Cloning will copy all attributes and
their values, but this method does not copy any text it contains unless
it is a DEEP clone, since the text is contained in a child text node.

When the optional argument DEEP is non-nil, this recursively clones the
subtree under the specified node; if false, clone only the node itself
(and its attributes, if it has any).

##### `(dom-node-has-attributes NODE)` ####

Return t when NODE has any attributes.

##### `(dom-node-has-child-nodes NODE)` ####

Return t when NODE has any child nodes.

##### `(dom-node-insert-before NODE NEW-CHILD &optional REF-CHILD)` ####

Insert NEW-CHILD before NODE's existing child REF-CHILD.
If optional argument REF-CHILD is nil or not given, insert NEW-CHILD at
the end of the list of NODE's children.
If NEW-CHILD is already in the document tree, it is first removed.
NEW-CHILD will be removed from anywhere in the document!
Return the node added.

##### `(dom-node-remove-child NODE OLD-CHILD)` ####

Remove OLD-CHILD from the list of NODE's children and return it.
This is very similar to `dom-node-unlink-child-from-parent` but it will
raise an exception if OLD-CHILD is NODE's child.

##### `(dom-node-replace-child NODE NEW-CHILD OLD-CHILD)` ####

Replace OLD-CHILD with NEW-CHILD in the list NODE's children.
Return OLD-CHILD.

##### `(dom-node-text-content NODE)` ####

Return the text content of NODE and its children.
If NODE is an attribute or a text node, its value is returned.

##### `(dom-node-set-text-content NODE DATA)` ####

Set the text content of NODE, replacing all its children.
If NODE is an attribute or a text node, its value is set.

##### `(dom-node-ancestor-p NODE ANCESTOR)` ####

Return t if ANCESTOR is an ancestor of NODE in the tree.

##### `(dom-node-valid-child NODE CHILD)` ####

Return t if CHILD is a valid child for NODE.
This depends on the node-type of NODE and CHILD.

##### `(dom-node-test-new-child NODE NEW-CHILD)` ####

Check wether NEW-CHILD is acceptable addition to NODE's children.

##### `(dom-node-unlink-child-from-parent NODE)` ####

Unlink NODE from is previous location.
This is very similar to `dom-node-remove-child` but it will check wether
this node is the child of a particular other node.

##### `(dom-node-list-item LIST INDEX)` ####

Return element at INDEX in LIST.
Equivalent to (nth INDEX NODE).

### Elements

##### `(dom-make-element-from-xml NODE OWNER)` ####

Make a DOM element based on NODE.
Called from `dom-make-node-from-xml`.
The atttributes are created by `dom-make-attribute-from-xml`.
OWNER is stored as the owner-document.

##### `(dom-element-get-elements-by-tag-name ELEMENT NAME)` ####

Return a list of all descendant of ELEMENT with tag NAME.
The elements are returned in the order in which they are encountered in
a preorder traversal of this element tree.

##### `(dom-make-attribute-from-xml ATTRIBUTE ELEMENT DOC)` ####

Make a DOM node of attributes based on ATTRIBUTE.
Called from `dom-make-element-from-xml`.
ELEMENT is the owner-element.
DOC is the owner-document.


