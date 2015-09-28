SHELL=/usr/bin/env bash
BUILD_DIR=build

# Installation directories
BINARY_DIR=/usr/bin
INSTALL_DIR=/usr/share/love-release
MANPAGE_DIR=/usr/share/man/man1
COMPLETION_DIR=/usr/share/bash-completion/completions


SED_INSTALL_DIR=$(shell echo "$(INSTALL_DIR)" | sed -e 's/[\/&]/\\&/g')

love-release: deps clean
	mkdir -p '$(BUILD_DIR)'
	longopt=$$(grep -m1 "LONG_OPTIONS" love-release.sh | sed -E 's/.*LONG_OPTIONS="(.*)"/\1/'); \
	for file in scripts/*.sh; do \
		s="$$(grep -E -m1 "^OPTIONS" "$$file" | sed -E "s/OPTIONS=(['\"]?)(.*)\1/\2/")"; \
		short="$${short}$${s}"; \
		s="$${s:0:1}"; \
		ll=$$(grep -E -m1 "^LONG_OPTIONS" "$$file" | sed -E "s/LONG_OPTIONS=(['\"]?)(.*)\1/\2/"); \
		long="$${long},$${s}$${longopt//,/,$$s}"; \
		if [[ -n $$ll ]]; then long="$${long},$${s}$${ll//,/,$$s}"; fi; \
		shelp="$$shelp\\n\\ -$$(grep "init_module" $$file | sed -Ee 's/init_module //' -e 's/" "/	/g' -e "s/\"//g" | awk -F "\t" '{print($$3,"  ",$$1)}')\\"; \
	done; \
	shelp="$$shelp\\n"; \
	sed -Ee "s/[^_]OPTIONS=(['\"]?)/ OPTIONS=\1$$short/" -e "s/LONG_OPTIONS=(['\"]?)(.*)\1/LONG_OPTIONS=\1\2$$long\1/" \
		-e 's/INSTALLED=false/INSTALLED=true/' \
		-e 's/SCRIPTS_DIR="scripts"/SCRIPTS_DIR="$(SED_INSTALL_DIR)\/scripts"/' \
		-e "$$(echo "$$(sed -n '/^EndOfSHelp/=' love-release.sh) i \\$$(printf "$$shelp")")" love-release.sh > '$(BUILD_DIR)/love-release'; \
	comp="$$(if [[ -n $$long ]]; then echo --$$long | tr -d ':' | sed -e 's/,$$//' -e 's/,/ --/g'; fi)$$(if [[ -n $$short ]]; then echo $$short | sed -E 's/(.)/ -\1/g'; fi) "; \
	sed -Ee "s/opts=\"(.*)/opts=\"$$comp\1/" completion.sh > '$(BUILD_DIR)/completion.sh'
	cp love-release.1 '$(BUILD_DIR)/love-release.1'
	gzip '$(BUILD_DIR)/love-release.1'

install:
	install -m 0755 '$(BUILD_DIR)/love-release' '$(BINARY_DIR)'
	install -m 0755 -d '$(INSTALL_DIR)' '$(INSTALL_DIR)/scripts' '$(COMPLETION_DIR)'
	install -m 0755 scripts/* '$(INSTALL_DIR)/scripts'
	install -m 0644 README.md conf.lua modules.md '$(INSTALL_DIR)'
	install -m 0644 '$(BUILD_DIR)/completion.sh' '$(COMPLETION_DIR)/love-release'
	install -m 0644 '$(BUILD_DIR)/love-release.1.gz' '$(MANPAGE_DIR)'

embedded: clean
	mkdir -p '$(BUILD_DIR)'
	longopt=$$(grep -m1 "LONG_OPTIONS" love-release.sh | sed -E 's/.*LONG_OPTIONS="(.*)"/\1/'); \
	for file in scripts/*.sh; do \
		module="$$(basename -s '.sh' "$$file")"; \
		content='(source <(cat <<\EndOfModule'$$'\n'"$$(cat $$file)"$$'\n''EndOfModule'$$'\n''))'$$'\n''default_module'$$'\n\n'; \
		echo "$$content" >> "$(BUILD_DIR)/tmp"; \
		s="$$(grep -E -m1 "^OPTIONS" "$$file" | sed -E "s/OPTIONS=(['\"]?)(.*)\1/\2/")"; \
		short="$${short}$${s}"; \
		s="$${s:0:1}"; \
		ll=$$(grep -E -m1 "^LONG_OPTIONS" "$$file" | sed -E "s/LONG_OPTIONS=(['\"]?)(.*)\1/\2/"); \
		long="$${long},$${s}$${longopt//,/,$$s}"; \
		if [[ -n $$ll ]]; then long="$${long},$${s}$${ll//,/,$$s}"; fi; \
		shelp="$$shelp\\n\\ -$$(grep "init_module" $$file | sed -Ee 's/init_module //' -e 's/" "/	/g' -e "s/\"//g" | awk -F "\t" '{print($$3,"  ",$$1)}')\\"; \
	done; \
	shelp="$$shelp\\n"; \
	sed -Ee "s/[^_]OPTIONS=(['\"]?)/ OPTIONS=\1$$short/" -e "s/LONG_OPTIONS=(['\"]?)(.*)\1/LONG_OPTIONS=\1\2$$long\1/" \
		-e 's/EMBEDDED=false/EMBEDDED=true/' \
		-e '/include_scripts_here$$/r $(BUILD_DIR)/tmp' \
		-e "$$(echo "$$(sed -n '/^EndOfSHelp/=' love-release.sh) i \\$$(printf "$$shelp")")" love-release.sh > '$(BUILD_DIR)/love-release.sh';
	chmod 0775 '$(BUILD_DIR)/love-release.sh'
	rm -rf '$(BUILD_DIR)/tmp'

deps:
	@if (( BASH_VERSINFO < 4 )); then \
		echo "Bash 4 is not installed."; \
	fi; \
	command -v curl > /dev/null 2>&1 || { \
		echo "curl is not installed."; \
		EXIT=true; \
	}; \
	command -v zip > /dev/null 2>&1 || { \
		echo "zip is not installed."; \
		EXIT=true; \
	}; \
	command -v unzip > /dev/null 2>&1 || { \
		echo "unzip is not installed."; \
		EXIT=true; \
	}; \
	command -v getopt > /dev/null 2>&1 || { \
		opt=false; \
	} && { \
		unset GETOPT_COMPATIBLE; \
		out=$$(getopt -T); \
		if (( $$? != 4 )) && [[ -n $$out ]]; then \
			opt=false; \
		fi; \
	}; \
	if [[ $$opt == false ]]; then \
		echo "GNU getopt is not installed."; \
		EXIT=true; \
	fi; \
	if ( ! command -v readlink > /dev/null 2>&1 || ! readlink -m / > /dev/null 2>&1 ) && command -v greadlink > /dev/null 2>&1; then \
		echo "GNU readlink is not installed."; \
		EXIT=true; \
	fi; \
	if [[ $$EXIT == true ]]; then false; fi

remove:
	rm -rf '$(BINARY_DIR)/love-release'
	rm -rf '$(INSTALL_DIR)'
	rm -rf '$(MANPAGE_DIR)/love-release.1.gz'
	rm -rf '$(COMPLETION_DIR)/love-release' '/etc/bash_completion.d/love-release'

clean:
	rm -rf '$(BUILD_DIR)'

