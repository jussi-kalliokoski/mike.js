COMPILE := mxmlc
COMPILE_FLAGS := -static-link-runtime-shared-libraries

IN := src/mike.as
OUT := mike.swf

$(OUT): $(IN)
	$(COMPILE) $(COMPILE_FLAGS) $^ -output $@
