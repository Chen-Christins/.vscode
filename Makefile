.PHONY: xx
xx:
	if [ -d "build" ]; then \
		cd build && $(MAKE); \
	else \
		mkdir build; \
		cd build && cmake ..; \
	fi
%:
	if [ -d "build" ]; then \
		cd build && +$(MAKE) $@; \
	else \
		mkdir build; \
		cd build && cmake ..; \
	fi
clean:
	if [ -d "build" ]; then \
		cd build && $(MAKE) clean; \
		rm -rf build; \
	fi