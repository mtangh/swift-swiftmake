#
# Makefile for swift project
#
MAKENAME  = $(notdir $(realpath $(lastword $(MAKEFILE_LIST))))
BASE_DIR  = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BASENAME  = $(notdir $(BASE_DIR))
_IS_ROOT  = $(strip $(shell [ "$(MAKELEVEL)" = "0" ] && echo yes))
#
# PROJECT LAYOUT
#
# <TARGNAME>
#   |
#   +- $(HEAD_DIR)/ -+- *.*
#   |
#   +- $(SRCS_DIR)/ -+- $(MOD_NAME)/ -+- $(CHEADDIR)
#                    |                |
#                    |                +- *.*
#                    |
#                    +- $(MOD_NAME)/ -+- ...
#                    |
#                    +- *.*
#                    :
#

# PROJECT DIR
ifeq    ($(strip $(PROJ_DIR)),)
ifeq    ($(_IS_ROOT),yes)
PROJ_DIR  = $(BASE_DIR)
else
PROJ_DIR  = $(shell dirname $(BASE_DIR))
endif # ($(_IS_ROOT),yes)
endif # ($(strip $(PROJ_DIR)),)

# PROJECT LAYOUTS
PROJNAME  = $(notdir $(PROJ_DIR))
HEAD_DIR  = head
SRCS_DIR  = src
RSRC_DIR  = $(SRCS_DIR)/resources
TEST_DIR  = tests
TRSRCDIR  = $(TEST_DIR)/resources

# INCLUDE THE PROJECT.MK
-include  $(PROJ_DIR)/Project.mk
ifneq   ($(PROJ_DIR),$(BASE_DIR))
-include  $(BASE_DIR)/Project.mk
endif # ($(PROJ_DIR),$(BASE_DIR))

# TARGET SETTINGS
PLATFORM ?= macosx
ifeq    ($(strip $(ARCHS)),)
ifneq   ($(strip $(ARCH)),)
ARCHS    ?= $(ARCH)
else
ARCHS    ?= x86_64
endif # ($(strip $(ARCH)),)
endif # ($(strip $(ARCHS)),)
ifneq   ($(strip $(CONFIGURATION)),)
CONFIG   ?= $(CONFIGURATION)
else
CONFIG   ?= Debug
endif # ($(strip $(CONFIGURATION)),)

# PROJECT OUTPUT DIRECTORIES
_TARGDIR  = target
_WORKDIR  = work

# OUTPUT DIRECTORY FOR PROJECT TARGET
TARG_DIR  = $(_TARGDIR)/$(PLATFORM)-$(CONFIG)
WORK_DIR  = $(_WORKDIR)/$(PLATFORM)-$(CONFIG)
OBJS_DIR  = $(WORK_DIR)/obj
TEMP_DIR  = $(WORK_DIR)/tmp

# SWIFT OBJECT OUTPUT
SWIFTDIR  = $(OBJS_DIR)/swift

# DIRECTORIES FOR C/C++/OBJC
CHEADDIR  = $(notdir $(HEAD_DIR))
COBJSDIR  = $(OBJS_DIR)/c

# HEADERS FOR C/C++/OBJC
PHEADERS  = $(strip $(shell : && { \
            find $(HEAD_DIR) -type f -a -name '*.h' -maxdepth 2; \
            } 2>/dev/null | sort))
MHEADERS  = $(strip $(shell : && { \
            find $(SRCS_DIR) -type f -a -name '*.h' |\
            grep -E "/$(CHEADDIR)/[^/]+"; \
            } 2>/dev/null | sort))

# PROJECT FILES
SRCFILES  = $(strip $(shell : && { \
            find $(SRCS_DIR) -type f -a -name '*.swift' ; \
            find $(SRCS_DIR) -type f -a -name '*.c'     ; \
            find $(SRCS_DIR) -type f -a -name '*.cc'    ; \
            find $(SRCS_DIR) -type f -a -name '*.cpp'   ; \
            find $(SRCS_DIR) -type f -a -name '*.cxx'   ; \
            find $(SRCS_DIR) -type f -a -name '*.m'     ; \
            find $(SRCS_DIR) -type f -a -name '*.mm'    ; \
            } 2>/dev/null |sort))
OBJFILES  = $(sort $(strip \
            $(patsubst $(SRCS_DIR)/%.swift,$(SWIFTDIR)/%.o,\
            $(filter %.swift,$(SRCFILES))) \
            $(patsubst $(SRCS_DIR)/%.c,    $(COBJSDIR)/%.o,\
            $(filter %.c,    $(SRCFILES))) \
            $(patsubst $(SRCS_DIR)/%.cc,   $(COBJSDIR)/%.o,\
            $(filter %.cc,   $(SRCFILES))) \
            $(patsubst $(SRCS_DIR)/%.cpp,  $(COBJSDIR)/%.o,\
            $(filter %.cpp,  $(SRCFILES))) \
            $(patsubst $(SRCS_DIR)/%.cxx,  $(COBJSDIR)/%.o,\
            $(filter %.cxx,  $(SRCFILES))) \
            $(patsubst $(SRCS_DIR)/%.m,    $(COBJSDIR)/%.o,\
            $(filter %.m,    $(SRCFILES))) \
            $(patsubst $(SRCS_DIR)/%.mm,   $(COBJSDIR)/%.o,\
            $(filter %.mm,   $(SRCFILES))) \
            ))

# DEPENDENCY FILE
DEPFILES  = $(sort $(strip \
            $(patsubst $(SRCS_DIR)/%.swift,$(SWIFTDIR)/%.d,\
            $(filter %.swift,$(SRCFILES))) \
            $(patsubst $(SRCS_DIR)/%.c,    $(COBJSDIR)/%.d,\
            $(filter %.c,    $(SRCFILES))) \
            $(patsubst $(SRCS_DIR)/%.cc,   $(COBJSDIR)/%.d,\
            $(filter %.cc,   $(SRCFILES))) \
            $(patsubst $(SRCS_DIR)/%.cpp,  $(COBJSDIR)/%.d,\
            $(filter %.cpp,  $(SRCFILES))) \
            $(patsubst $(SRCS_DIR)/%.cxx,  $(COBJSDIR)/%.d,\
            $(filter %.cxx,  $(SRCFILES))) \
            $(patsubst $(SRCS_DIR)/%.m,    $(COBJSDIR)/%.d,\
            $(filter %.m,    $(SRCFILES))) \
            $(patsubst $(SRCS_DIR)/%.mm,   $(COBJSDIR)/%.d,\
            $(filter %.mm,   $(SRCFILES))) \
            ))

# CHILD PROJECTS
ifneq   ($(strip $(CHILDS)),)
SUBPROJS += $(strip $(CHILDS))
endif # ($(strip $(CHILDS)),)
ifneq   ($(strip $(SUBPROJECTS)),)
SUBPROJS += $(strip $(SUBPROJECTS))
endif # ($(strip $(SUBPROJECTS)),)
ifeq    ($(strip $(SUBPROJS)),)
SUBPROJS += $(strip $(notdir $(shell \
            cd $(BASE_DIR) && { \
            find . -type d -maxdepth 1 \
            ! -name '.*' \
            ! -name '$(notdir $(HEAD_DIR))' \
            ! -name '$(notdir $(SRCS_DIR))' \
            ! -name '$(notdir $(TEST_DIR))' \
            ! -name '$(notdir $(_TARGDIR))' \
            ! -name '$(notdir $(_WORKDIR))' \
            ; } 2>/dev/null |sort )))
endif # ($(strip $(SUBPROJS)),)

# MODULES
ifneq   ($(strip $(MODULES)),)
MODNAMES  = $(strip $(MODULES))
endif # ($(strip $(MODULES)),)
ifeq    ($(strip $(MODNAMES)),)
MODNAMES  = $(strip $(notdir $(shell \
            cd $(BASE_DIR) && { \
            find $(SRCS_DIR) -type d -maxdepth 1 \
            ! -name '.*' \
            ! -name '$(notdir $(HEAD_DIR))' \
            ! -name '$(notdir $(SRCS_DIR))' \
            ! -name '$(notdir $(TEST_DIR))' \
            ! -name '$(notdir $(RSRC_DIR))' \
            ; } 2>/dev/null |sort )))
endif # ($(strip $(MODNAMES)),)

# PROJECT TARGET
ifeq    ($(strip $(TARGET)),)
TARGET    = $(notdir $(BASENAME))
endif # ($(strip $(TARGET)),)
TARGNAME  = $(strip $(basename $(TARGET)))
ifneq   ($(strip $(findstring .,$(TARGET))),)
TARGTYPE  = $(shell n="$(TARGET)";echo "$${n\#\#*.}"|tr '[A-Z]' '[a-z]')
else
TARGTYPE  =
endif # ($(strip $(findstring .,$(TARGET))),)

# TARGET NAME WITH ARCHITECTURE
TARGSETS  = $(strip $(addsuffix /$(TARGNAME),$(ARCHS)))

# TARGET DEPENDENCIES
ifneq   ($(strip $(SRCFILES)),)
TDEPENDS  = $(strip $(DEPENDS))
ifneq   ($(strip $(SUBPROJS)),)
TDEPENDS += $(strip $(addprefix _subproj_/,$(SUBPROJS)))
endif # ($(strip $(SUBPROJS)),)
ifneq   ($(strip $(MODNAMES)),)
TDEPENDS += $(strip $(addprefix _module_/,$(MODNAMES)))
endif # ($(strip $(MODNAMES)),)
ifeq    ($(TARGTYPE),)
TDEPENDS += $(TARG_DIR)/$(TARGNAME)
else
ifeq    ($(strip $(TARGTYPE)),framework)
TDEPENDS += $(TARG_DIR)/$(TARGNAME).$(TARGTYPE)
else
TDEPENDS += $(TARG_DIR)/$(TARGNAME).$(TARGTYPE)
endif # ($(strip $(TARGTYPE)),framework)
endif # ($(TARGTYPE),)
else
TDEPENDS  =
endif # ($(strip $(SRCFILES)),)

# PACKAGE NAME
PKG_NAME  = $(PROJNAME).tgz

# PROJECT LAYOUTS
PROJDIRS  = $(HEAD_DIR) \
            $(SRCS_DIR) \
            $(RSRC_DIR) \
            $(TEST_DIR) \
            $(TRSRCDIR)
_MK_DIRS  = $(TARG_DIR) \
            $(WORK_DIR) \
            $(OBJS_DIR) \
            $(SWIFTDIR) \
            $(COBJSDIR) \
            $(TEMP_DIR)
_RM_DIRS  = $(_TARGDIR) \
            $(_WORKDIR)

# XCODE
ifneq   ($(strip $(DEVELOPER_DIR)),)
XROOTDIR  = $(strip $(DEVELOPER_DIR))
else
XROOTDIR  = $(shell xcode-select --print-path)
endif # ($(strip $(DEVELOPER_DIR)),)

# XCODE SDK PATH
ifneq   ($(strip $(SDKROOT)),)
XSDKPATH  = $(SDKROOT)
else
XSDKPATH  = $(shell xcrun --show-sdk-path -sdk $(PLATFORM))
endif # ($(strip $(SDKROOT)),)
ifneq   ($(strip $(SDK_VERSION)),)
XSDK_VER  = $(SDK_VERSION)
else
XSDK_VER  = $(shell xcrun --show-sdk-version -sdk $(PLATFORM))
endif # ($(strip $(SDK_VERSION)),)

# XCODE TOOLCHAIN PATH
ifneq   ($(strip $(DT_TOOLCHAIN_DIR)),)
XTC_PATH  = $(DT_TOOLCHAIN_DIR)
else
XTC_NAME  = XcodeDefault
XTC_PATH  = $(XROOTDIR)/Toolchains/$(XTC_NAME).xctoolchain
endif # ($(strip $(DT_TOOLCHAIN_DIR)),)

# SWIFT RUNTIME LIBRARY PATH
SWRTPATH  = $(XTC_PATH)/usr/lib/swift/$(PLATFORM)

# COMMANDS
XC_BUILD  = $(shell which xcodebuild)
SWIFT     = $(shell xcrun -f swift)
SWIFTC    = $(shell xcrun -f swiftc)
CC        = $(shell xcrun -f cc)
CXX       = $(shell xcrun -f c++)
CPP       = $(shell xcrun -f cpp)
CLANG     = $(shell xcrun -f clang)
CLANGXX   = $(shell xcrun -f clang++)
AR        = $(shell xcrun -f ar)
LD        = $(shell xcrun -f ld)
LIPO      = $(shell xcrun -f lipo)

# SWIFT SETTINGS
ifndef  SWIFLAGS
SWIFLAGS  = -frontend -color-diagnostics
SWIFLAGS += -sdk $(XSDKPATH)
SWIFLAGS += -enable-objc-interop
SWIFLAGS += -module-name $(basename $(TARGNAME))
SWIFLAGS += -module-link-name $(basename $(TARGNAME))
ifneq   ($(strip $(DEPENDS)),)
SWIFLAGS += $(addprefix -I ,$(addsuffix /$(TARG_DIR),$(MOD_DEPS)))
SWIFLAGS += $(addprefix -L ,$(addsuffix /$(TARG_DIR),$(MOD_DEPS)))
endif # ($(strip $(DEPENDS)),)
ifneq   ($(strip $(MODNAMES)),)
SWIFLAGS += $(addprefix -I ,$(addsuffix /$(TARG_DIR),$(MODNAMES)))
SWIFLAGS += $(addprefix -L ,$(addsuffix /$(TARG_DIR),$(MODNAMES)))
endif # ($(strip $(MODNAMES)),)
endif # SWIFLAGS

# CLANG SETTINGS
ifndef  CLFLAGS
CLFLAGS   =
endif

# COMPILER SETTINGS
ifndef  CFLAGS
CFLAGS    =
ifneq   ($(CONFIGURATION),Release)
CFLAGS   += -O
endif # ($(CONFIGURATION),Release)
ifeq    ($(CONFIGURATION),Debug)
CFLAGS   += -g -Onone
endif # ($(CONFIGURATION),Debug)
endif # CFLAGS

# LINKER SETTINGS
ifndef  LDFLAGS
LDFLAGS   = -syslibroot $(XSDKPATH)
LDFLAGS  += -arch $(ARCH)
LDFLAGS  += -lobjc -lSystem
LDFLAGS  += -macosx_version_min $(XSDK_VER)
LDFLAGS  += -no_objc_category_merging
LDFLAGS  += -L $(SWRTPATH)
endif # LDFLAGS

# MISC.
P   = printf -- '[$(BASENAME)] %s'
PN  = printf -- '[$(BASENAME)] %s\n'
LN  = $$(for i in {1..68};do printf '-';done)

# PROJECT.MK
define  PROJECTMK
# Project.mk
#------------

# Build target
#TARGET =

# Build platfoem
PLATFORM ?= macosx

# Build architecture
ARCHS ?= x86_64

# Build configuration
#CONFIGURATION ?= Release
CONFIGURATION ?= Debug

# Dependent projects
#DEPENDS =

endef # PROJECTMK
export  PROJECTMK

# PHONY TARGETS
.PHONY: all build rebuild depends package init clean clean-all
.PHONY: childs frameworks modules libs
.PHONY: $(TARGNAME)

# SUFFIXES
.SUFFIXES: .swift .swiftmodule .swiftdoc
.SUFFIXES: .app .framework .dylib .so .a

###
###
### BUILD RULES
###
###

#-
#- DEFAULT TARGET
#-

all: build

#-
#- BUILD
#-

build:  _info \
        $(TARG_DIR) \
        _head \
        $(TARGNAME)

rebuild: \
        clean \
        init  \
        build

#-
#- BUILD INFO
#-

_head:
	@printf -- "$(LN)\r[$(BASENAME)] "; echo

_info:  _head
	@$(PN) 'INFO>'; \
	 $(PN) '- BASEDIR : $(BASE_DIR)'; \
	 if [ "$(_IS_ROOT)" = "yes" ]; then \
	  $(PN) '- PROJECT : $(PROJNAME)'; \
	 else \
	  $(PN) '- PROJECT : $(BASENAME) in $(PROJNAME)'; \
	 fi; \
	 if [ "$(strip $(TARGTYPE))" = "" ]; then \
	  $(PN) '- TARGET  : $(basename $(TARGNAME))'; \
	 else \
	  $(PN) '- TARGET  : $(basename $(TARGNAME)).$(TARGTYPE)'; \
	 fi; \
	 $(PN) '- PLATFORM: $(PLATFORM)'; \
	 $(PN) '- CONFIG  : $(CONFIG)'; \
	 [ -n "$(strip $(ARCHS))" ] && { \
	  $(PN) '- ARCHS   :'; \
	  for arch in $(strip $(ARCHS)); do \
	  $(PN) "  - $${arch}"; done; } || :; \
	 [ -n "$(strip $(SUBPROJS))" ] && { \
	  $(PN) '- SUBPROJS:'; \
	  for subproj in $(strip $(SUBPROJS)); do \
	  $(PN) "  - $${subproj}"; done; } || :; \
	 [ -n "$(strip $(SUBPROJS))" ] && { \
	  $(PN) '- MODULES :'; \
	  for module in $(strip $(MODNAMES)); do \
	  $(PN) "  - $${module}"; done; } || :;

#-
#- BUILD RULES FOR PROJECT TARGET
#-

$(TARGNAME): \
        $(strip $(addprefix $(TARG_DIR)/,$(TARGSETS)))
	@$(LIPO) -create \
	 $(addprefix $(addprefix -arch ,$(dir $(TARGSETS))) ,$(TARGSETS)) \
	 -output $(TARGNAME)

$(TARG_DIR)/%/$(TARGNAME): \
        ARCH = $(strip %)

$(TARG_DIR)/%/$(TARGNAME): \
        $(strip $(TDEPENDS))

# BUILDING THE FRAMEWORK
$(TARG_DIR)/$(TARGNAME).framework: \
        $(TARG_DIR)/lib$(TARGNAME).a \
        $(SRCS_DIR)/module.modulemap \
        $(RSRC_DIR)/Info.plist
	@$(PN) "MAKE FRAMEWORK '$(notdir $@)'"
	@mkdir -p $@; cd $@; \
	 for dir in Modules Headers Resources; \
	 do mkdir -p "./$$dir"; done; \
	 cp $(SRCS_DIR)/module.modulemap Modules/; \
	 cp -fr $(HEAD_DIR)/* Headers/; \
	 cp -fr $(RSRC_DIR)/* Resources/; \
	 cp -f $< ${TARGNAME}
	@find . |sort |while read entry; do \
	 $(PN) "- $$entry"; done

# MAKE EXECUTABLE
$(TARG_DIR)/%/$(TARGNAME): \
        $(OBJFILES)
	@$(PN) "MAKE EXECUTABLE '$(notdir $@)'"
	 $(LD) $(LDFLAGS) -o $@ $^

# MERGE PARTIAL OF THE MODULE
$(TARG_DIR)/$(TARGNAME).swiftmodule: \
        $(OBJFILES)
	 $(PN) "MERGE-MODULE: $(BASENAME)/$(notdir $@)"
	 $(SWIFT) $(SWIFLAGS) $(CFLAGS) \
	 -parse-as-library \
	 -emit-module \
	 -emit-module-path $@ \
	 -emit-module-doc-path $(TARG_DIR)/$(notdir $*).swiftdoc \
	 $(patsubst %.o,%.swiftmodule,$^)

# BUILDING DYNAMIC LIB
$(TARG_DIR)/lib$(TARGNAME).dylib: \
        $(OBJFILES)
	@$(PN) "BUILD DYNAMIC LIB: $(BASENAME)/$(notdir $@)"
	 $(LD) $(LDFLAGS) -rpath $(SWRTPATH) -dylib -o $@ $^

# BUILDING STATIC LIB
$(TARG_DIR)/lib%.a: \
        $(OBJFILES)
	@$(PN) "BUILD STATIC LIB: $(BASENAME)/$(notdir $@)"
	 $(LD) $(LDFLAGS) -static -o $@ $^

#-
#- MAKE DEPENDENCY
#-

depend: $(strip $(DEPFILES))

ifneq   ($(strip $(SRCFILES)),)
$(SWIFTDIR)/%.dep: \
        $(SRCS_DIR)/%.swift \
        $(filter $(SRCS_DIR)/%.swift,$(SRCFILES))
	@$(PN) "COMPILING WITH MODS: $(BASENAME)/$(notdir $@)"
	@mkdir -p "$(dir $@)"
	 $(SWIFT) $(SWIFLAGS) $(CFLAGS) \
	 -parse-as-library \
	 -emit-object \
	 -emit-module-path $(SWIFTDIR)/$*.swiftmodule \
	 -emit-module-doc-path $(SWIFTDIR)/$*.swiftdoc \
	 -primary-file $< \
	 $(filter-out $<,$(filter $(dir $<)%.swift,$(SRCFILES))) \
	 -o $@
endif # ($(strip $(SRCFILES)),)

ifneq   ($(strip $(SRCFILES)),)
$(COBJSDIR)/%.dep: \
        $(SRCS_DIR)/%.c \
        $(strip $(PHEADERS)) \
        $(strip $(wildcard $(dir $(SRCS_DIR)/%.c)$(CHEADDIR)/*.h)) \
        $(strip $(wildcard $(dir $(SRCS_DIR)/%.c)*.h))
	$(PN) "COMPILING: $@"
	@mkdir -p "$(dir $@)"
	 $(CLANG) $(CLFLAGS) $(CFLAGS) $< -o $@
endif # ($(strip $(SRCFILES)),)

#-
#- BUILD CHILDS
#-

childs: libs \
        swiftmodules \
        frameworks

#-
#- BUILD SUB-PROJECT
#-

frameworks: \
        _head \
        $(strip $(filter %.framework,$(SUBPROJS)))

swiftmodules: \
        _head \
        $(strip $(filter %.swiftmodule,$(SUBPROJS)))

libs:   _head \
        $(strip $(filter %.dylib,$(SUBPROJS))) \
        $(strip $(filter %.a,$(SUBPROJS)))

_subproj_/%:
ifneq   ($(strip $(SUBPROJS)),)
	@subproj="$(strip $(patsubst _subproj_/%,%,$@))"
	 if [ -n "$$subproj" ]; then \
	  retval=128; \
	  for dir in $(BASE_DIR) $(PROJ_DIR) ..; do \
	   [ -e "$$dir/$$subproj/$(MAKENAME)" ] || continue; \
	   $(PN) "BUILDING SUB-PROJECT '$$subproj'"; \
	   $(MAKE) -C "$$dir/$$subproj"; retval=$$?; break; \
	  done; \
	  test $$retval -eq 0; \
	 fi;
endif # ($(strip $(SUBPROJS)),)

#-
#- BUILD INTERNAL MODULES
#-

modules: \
        _head \
        $(strip $(addprefix _module_/,$(MODNAMES)))

ifneq   ($(strip $(MODNAMES)),)
_module_/%: \
        $(strip \
        $(filter $(addprefix $(COBJSDIR)/,%)/,$(OBJFILES)) \
        $(filter $(addprefix $(SWIFTDIR)/,%)/,$(OBJFILES)) \
        )
endif # ($(strip $(MODNAMES),)

#-
#- BUILD RULES FOR PROJECT FILES
#-

ifneq   ($(strip $(SRCFILES)),)
$(SWIFTDIR)/%.o: \
        $(SRCS_DIR)/%.swift \
        $(filter $(SRCS_DIR)/%.swift,$(SRCFILES))
	@$(PN) "COMPILING WITH MODS: $(BASENAME)/$(notdir $@)"
	@mkdir -p "$(dir $@)"
	 $(SWIFT) $(SWIFLAGS) $(CFLAGS) \
	 -parse-as-library \
	 -emit-object \
	 -emit-module-path $(SWIFTDIR)/$*.swiftmodule \
	 -emit-module-doc-path $(SWIFTDIR)/$*.swiftdoc \
	 -primary-file $< \
	 $(filter-out $<,$(filter $(dir $<)%.swift,$(SRCFILES))) \
	 -o $@
endif # ($(strip $(SRCFILES)),)

#-
#- BUILD RULES FOR C/C++/OBJC
#-

ifneq   ($(strip $(SRCFILES)),)
$(COBJSDIR)/%.o: \
        $(SRCS_DIR)/%.c \
        $(strip $(PHEADERS)) \
        $(strip $(wildcard $(dir $(SRCS_DIR)/%.c)$(CHEADDIR)/*.h)) \
        $(strip $(wildcard $(dir $(SRCS_DIR)/%.c)*.h))
	$(PN) "COMPILING: $@"
	@mkdir -p "$(dir $@)"
	 $(CLANG) $(CLFLAGS) $(CFLAGS) $< -o $@
endif # ($(strip $(SRCFILES)),)

#-
#- PACKAGE
#-

package:

#-
#- CLEANUP
#-

.PHONY: _cleanall _rmdirs

clean: _head _rmdirs

clean-all: _head _cleanall _rmdirs

_cleanall:
ifneq   ($(strip $(SUBPROJS)),)
	@$(PN) "CLEANUP-CHILDS>"
	-@for subproj in $(strip $(SUBPROJS)); do \
	   target="$(BASE_DIR)/$${subproj}"; \
	   [ -n "$${subproj}" -a -d "$${target}" ] || continue; \
	   [ -e "$${target}/$(MAKENAME)" ] || continue; \
	   $(PN) "- $${target##*/}"; \
	   $(MAKE) -C "$${target}" clean-all; \
	  done
endif # ($(strip $(SUBPROJS)),)

_rmdirs:
ifneq   ($(strip $(_RM_DIRS)),)
	-@_print=0; \
	  for dir in $(_RM_DIRS); do \
	   [ $$_print -eq 0 ] && $(PN) "RMDIRS>" || :; \
	   $(PN) "- $${dir##$(BASE_DIR)/}" && \
	   $(RM) -r "$$dir"; \
	   _print=1; \
	  done
endif # ($(strip $(_RM_DIRS)),)

#-
#- PROJECT.MK
#-

$(BASE_DIR)/Project.mk:
ifeq    ($(_IS_ROOT),yes)
	-@[ ! -e "$@" ] && { \
	 $(PN) 'CREATE $(PROJNAME)/$(notdir $@)'; \
	 echo "$${PROJECTMK}" >"$@"; }
endif # ($(_IS_ROOT),yes)

#-
#- INITIALIZE PROJECTS
#-

.PHONY: init-layouts init-makefiles
.PHONY: _init_head _layouts _makefiles _init-subprojs

init:   _init_head _layouts _makefiles _init-subprojs

init-layouts: \
        _init_head _layouts

init-makefiles: \
        _init_head _makefikes

init-subprojs: \
        _init_head _init-subprojs

_init_head: _head
	@$(PN) "INIT>"

_layouts:
	@$(PN) "- LAYOUTS"
	-@for dir in $(PROJDIRS); do \
	   [ ! -d "$$dir" ] && \
	   $(PN) "  - MKDIR: $${dir##$(PROJ_DIR)/}" && \
	   mkdir -p "$$dir"; :;\
	  done

_makefiles: \
        _makefiles_head \
        $(addprefix $(BASE_DIR)/,\
        $(addsuffix /$(MAKENAME),$(strip $(SUBPROJS))))

_makefiles_head:
ifneq   ($(strip $(SUBPROJS)),)
	@$(PN) "- CLONING MAKEFILE ($(MAKENAME)):"
endif # ($(strip $(SUBPROJS)),)

$(BASE_DIR)/%/$(MAKENAME): \
        $(BASE_DIR)/$(MAKENAME)
ifneq   ($(strip $(SUBPROJS)),)
	-@[ -d "$(dir $@)" ] && { \
	  $(PN) "  - COPY: '$(dir $(patsubst $(BASE_DIR)/%,%,$@))$(MAKENAME)'"; \
	  cp -f "$<" "$@"; }
endif # ($(strip $(SUBPROJS)),)

_init-subprojs:
ifneq   ($(strip $(SUBPROJS)),)
	-@for subproj in $(strip $(SUBPROJS)); do \
	  [ -e "$${subproj}/$(MAKENAME)" ] && { \
	  $(MAKE) -C "$${subproj}" init; }; done; :
endif # ($(strip $(SUBPROJS)),)

#-
#- MAKE OUTPUTS
#-

.PHONY: _mkdirs

# TARGET DIRECTORY
$(TARG_DIR): _mkdirs

# MAKE OUTPUT DIRECTORIES
_mkdirs:
	-@_print=0; \
	  for dir in $(_MK_DIRS); do \
	   if [ -n "$$dir" -a ! -d "$$dir" ]; then \
	     [ $$_print -eq 0 ] && $(PN) "MKDIRS>" || :; \
	     $(PN) "- $${dir##*$(PROJ_DIR)/}"; \
	     mkdir -p "$$dir"; \
	     _print=1; \
	   fi; \
	  done

#eof
