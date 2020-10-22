BUILD := gprbuild

PROGRAMMES := makedict makeefil makeewds makeinfl makestem meanings wakedict \
  words

.PHONY: all

all: $(PROGRAMMES) data

# Targets delegated to gprbuild are declared phony even if they build
# concrete files, because Make ignores all about Ada dependencies.
.PHONY: $(PROGRAMMES)
$(PROGRAMMES):
	$(BUILD) -p -j4 -Pwords $@

.PHONY: sorter
sorter:
	$(BUILD) -p -j4 -Ptools $@

# Executable targets are phony (see above), so we tell Make to only
# check that they exist but ignore the timestamp.  This is not
# perfect, but at least Make
# * updates the output data if the input data changes
# * builds the generator if it does not exist yet

DICTFILE.GEN: DICTLINE.GEN | wakedict
	echo g | bin/wakedict $< > /dev/null
	mv STEMLIST.GEN STEMLIST_generated.GEN

STEMLIST.GEN: DICTLINE.GEN | sorter
	rm -f -- $@
	bin/sorter < stemlist-sort.txt > /dev/null
	mv -f -- STEMLIST_new.GEN $@
	rm -f STEMLIST_generated.GEN
	rm -f WORK.

EWDSFILE.GEN: EWDSLIST.GEN | makeefil
	bin/makeefil

EWDSLIST.GEN: DICTLINE.GEN | makeewds
	echo g | bin/makeewds $< > /dev/null
	sort -o $@ $@

INFLECTS.SEC: INFLECTS.LAT | makeinfl
	bin/makeinfl $< > /dev/null

STEMFILE.GEN INDXFILE.GEN: STEMLIST.GEN | makestem
	echo g | bin/makestem $< > /dev/null

GENERATED_DATA_FILES := DICTFILE.GEN STEMFILE.GEN INDXFILE.GEN EWDSLIST.GEN \
					INFLECTS.SEC EWDSFILE.GEN STEMLIST.GEN

.PHONY: data

data: $(GENERATED_DATA_FILES)

.PHONY: clean_data

clean_data:
	rm -f $(GENERATED_DATA_FILES) CHECKEWD.

.PHONY: clean

clean: clean_data
	rm -fr bin lib obj
	rm -f WORK. STEMLIST_generated.GEN STEMLIST_new.GEN

.PHONY: test

test: all
	cd test && ./run-tests.sh
