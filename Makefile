# Makefile for dqn-tx1-for-nintendo

SUBDIRS = vidcap gpio term imshow

.PHONY: all clean subdirs $(SUBDIRS)

all: subdirs

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); \
	do \
		$(MAKE) -C "$${dir}" clean; \
	done
