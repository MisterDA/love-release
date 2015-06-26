BUILD_DIR=build

# Installation directories
BINARY_DIR=/usr/bin
INSTALL_DIR=/usr/share/love-release
MANPAGE_DIR=/usr/share/man/man1
COMPLETION_DIR=/usr/share/bash-completion/completions


SED_INSTALL_DIR=$(shell echo "$(INSTALL_DIR)" | sed -e 's/[\/&]/\\&/g')

love-release: clean
	mkdir -p '$(BUILD_DIR)'
	longopt=$$(grep "^LONG_OPTIONS" love-release.sh | sed -re 's/LONG_OPTIONS="(.*)"/\1/'); \
	for file in scripts/*.sh; do \
		s="$$(grep -E -m 1 "^OPTIONS=['\"]?.*['\"]?" "$$file" | sed -re "s/OPTIONS=['\"]?//" -e "s/['\"]?$$//")"; \
		short="$${s}$${short}"; \
		l="$$s$$(echo "$$longopt" | sed -e "s/,/,$${s}/g")"; \
		ll="$$(grep -E -m 1 "^LONG_OPTIONS=['\"]?.*['\"]?" "$$file" | sed -re "s/LONG_OPTIONS=['\"]?//" -e "s/['\"]?$$//" -e "s/,/,$${s}/g")"; \
		if [[ -n $$ll ]]; then l="$${l},$${s}$${ll}"; fi; \
		long="$${l},$${long}"; \
		if [[ -n $$shelp ]]; then shelp="$$shelp\n"; fi; \
		shelp="$$shelp -$$(grep "init_module" $$file | sed -e 's/init_module //' -e 's/" "/\t/g' -e 's/"//g' | awk -F "\t" '{print($$3,"  ",$$1)}')"; \
	done; \
	sed -re "s/^OPTIONS=(['\"]?)/OPTIONS=\1$$short/" -e "s/^LONG_OPTIONS=(['\"]?)/LONG_OPTIONS=\1$$long/" \
		-e 's/INSTALLED=false/INSTALLED=true/' \
		-e "/^EndOfSHelp/ i\\$$shelp" \
		-e 's/SCRIPTS_DIR="scripts"/SCRIPTS_DIR="$(SED_INSTALL_DIR)\/scripts"/' love-release.sh > '$(BUILD_DIR)/love-release'; \
	comp="$$(if [[ -n $$long ]]; then echo --$$long | tr -d ':' | sed -e 's/,$$//' -e 's/,/ --/g'; fi)$$(if [[ -n $$short ]]; then echo $$short | sed -r 's/(.)/ -\1/g'; fi) "; \
	sed -re "s/opts=\"(.*)/opts=\"$$comp\1/" completion.sh > '$(BUILD_DIR)/completion.sh'
	cp love-release.1 '$(BUILD_DIR)/love-release.1'
	gzip '$(BUILD_DIR)/love-release.1'

install:
	install -m 0755 '$(BUILD_DIR)/love-release' '$(BINARY_DIR)'
	install -m 0755 -d '$(INSTALL_DIR)' '$(INSTALL_DIR)/scripts' '$(COMPLETION_DIR)'
	install -m 0755 scripts/* '$(INSTALL_DIR)/scripts'
	install -m 0644 -t '$(INSTALL_DIR)' README.md conf.lua example.sh
	install -m 0644 '$(BUILD_DIR)/completion.sh' '$(COMPLETION_DIR)/love-release'
	install -m 0644 '$(BUILD_DIR)/love-release.1.gz' '$(MANPAGE_DIR)'

embedded: clean
	mkdir -p '$(BUILD_DIR)'
	longopt=$$(grep "^LONG_OPTIONS" love-release.sh | sed -re 's/LONG_OPTIONS="(.*)"/\1/'); \
	for file in scripts/*.sh; do \
		module="$$(basename -s '.sh' "$$file")"; \
		content='(source <(cat <<\EndOfModule'$$'\n'"$$(cat $$file)"$$'\n''EndOfModule'$$'\n''))'$$'\n''default_module'$$'\n\n'; \
		echo "$$content" >> "$(BUILD_DIR)/tmp"; \
		s="$$(grep -E -m 1 "^OPTIONS=['\"]?.*['\"]?" "$$file" | sed -re "s/OPTIONS=['\"]?//" -e "s/['\"]?$$//")"; \
		short="$${s}$${short}"; \
		l="$$s$$(echo "$$longopt" | sed -e "s/,/,$${s}/g")"; \
		ll="$$(grep -E -m 1 "^LONG_OPTIONS=['\"]?.*['\"]?" "$$file" | sed -re "s/LONG_OPTIONS=['\"]?//" -e "s/['\"]?$$//" -e "s/,/,$${s}/g")"; \
		if [[ -n $$ll ]]; then l="$${l},$${s}$${ll}"; fi; \
		long="$${l},$${long}"; \
		shelp="$$shelp -$$(grep "init_module" $$file | sed -e 's/init_module //' -e 's/" "/\t/g' -e 's/"//g' | awk -F "\t" '{print($$3,"  ",$$1)}')"; \
	done; \
	sed -re "s/^OPTIONS=(['\"]?)/OPTIONS=\1$$short/" -e "s/^LONG_OPTIONS=(['\"]?)/LONG_OPTIONS=\1$$long/" \
		-e 's/EMBEDDED=false/EMBEDDED=true/' \
		-e "/^EndOfSHelp/ i\\$$shelp" \
		-e '/include_scripts_here$$/r $(BUILD_DIR)/tmp' love-release.sh > '$(BUILD_DIR)/love-release.sh'
	chmod 0775 '$(BUILD_DIR)/love-release.sh'
	rm -rf '$(BUILD_DIR)/tmp'

remove:
	rm -rf '$(BINARY_DIR)/love-release'
	rm -rf '$(INSTALL_DIR)'
	rm -rf '$(MANPAGE_DIR)/love-release.1.gz'
	rm -rf '$(COMPLETION_DIR)/love-release' '/etc/bash_completion.d/love-release'

clean:
	rm -rf '$(BUILD_DIR)'

