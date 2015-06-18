BUILD_DIR=build

# Installation directories
BINARY_DIR=/usr/bin
INSTALL_DIR=/usr/share/love-release
MANPAGE_DIR=/usr/share/man/man1
COMPLETION_DIR=/usr/share/bash-completion/completions


SED_INSTALL_DIR=$(shell echo "$(INSTALL_DIR)" | sed -e 's/[\/&]/\\&/g')

love-release: clean
	mkdir -p $(BUILD_DIR)
	for file in scripts/*.sh; do \
		short="$${short}$$(grep -E -m 1 "^OPTIONS=['\"]?.*['\"]?" "$$file" | sed -r -e "s/OPTIONS=['\"]?//" -e "s/['\"]?$$//")"; \
		long="$${long}$$(grep -E -m 1 "^LONG_OPTIONS=['\"]?.*['\"]?" "$$file" | sed -r -e "s/LONG_OPTIONS=['\"]?//" -e "s/['\"]?$$//")"; \
	done; \
	if [[ -n $$long && $${long: -1} != ',' ]]; then long="$${long},"; fi; \
	sed -re "s/^OPTIONS=(['\"]?)/OPTIONS=\1$$short/" -e "s/^LONG_OPTIONS=(['\"]?)/LONG_OPTIONS=\1$$long/" \
		-e 's/INSTALLED=false/INSTALLED=true/' \
		-e 's/SCRIPTS_DIR="scripts"/SCRIPTS_DIR="$(SED_INSTALL_DIR)\/scripts"/' love-release.sh > '$(BUILD_DIR)/love-release'
	cp love-release.1 '$(BUILD_DIR)/love-release.1'
	gzip '$(BUILD_DIR)/love-release.1'

install:
	install -m 0755 '$(BUILD_DIR)/love-release' '$(BINARY_DIR)'
	install -m 0755 -d '$(INSTALL_DIR)' '$(INSTALL_DIR)/scripts' '$(COMPLETION_DIR)'
	install -m 0755 scripts/* '$(INSTALL_DIR)/scripts'
	install -m 0644 -t '$(INSTALL_DIR)' README.md conf.lua example.sh
	install -m 0644 completion.sh '$(COMPLETION_DIR)/love-release'
	install -m 0644 '$(BUILD_DIR)/love-release.1.gz' '$(MANPAGE_DIR)'

embedded: clean
	mkdir -p '$(BUILD_DIR)'
	for file in scripts/*.sh; do \
		module="$$(basename -s '.sh' "$$file")"; \
		content='(source <(cat <<\EndOfModule'$$'\n'"$$(cat $$file)"$$'\n''EndOfModule'$$'\n''))'$$'\n''default_module'$$'\n\n'; \
		echo "$$content" >> "$(BUILD_DIR)/tmp"; \
		short="$${short}$$(grep -E -m 1 "^OPTIONS=['\"]?.*['\"]?" "$$file" | sed -r -e "s/OPTIONS=['\"]?//" -e "s/['\"]?$$//")"; \
		long="$${long}$$(grep -E -m 1 "^LONG_OPTIONS=['\"]?.*['\"]?" "$$file" | sed -r -e "s/LONG_OPTIONS=['\"]?//" -e "s/['\"]?$$//")"; \
	done; \
	if [[ -n $$long && $${long: -1} != ',' ]]; then long="$${long},"; fi; \
	sed -re "s/^OPTIONS=(['\"]?)/OPTIONS=\1$$short/" -e "s/^LONG_OPTIONS=(['\"]?)/LONG_OPTIONS=\1$$long/" \
		-e 's/EMBEDDED=false/EMBEDDED=true/' \
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

