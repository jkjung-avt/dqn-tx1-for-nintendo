# Makefile for dqn-tx1-for-nintendo

SUBDIRS = vidcap

.PHONY: all clean subdirs $(SUBDIRS)

all: subdirs

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

