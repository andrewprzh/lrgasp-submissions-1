testrootdir = ..
include ${testrootdir}/testing.mk

bad_gtfs = $(wildcard input/bad_*.gtf)
bad_tests = $(basename $(notdir ${bad_gtfs}))

test: example_tests test_example_gz bad_tests

example_tests: $(addsuffix _model_test,$(wildcard ${darwindir}/iso_detect_ref_*/*/models.gtf))

%_model_test: mkout
	${lrgasp_validate_models} $*

test_example_gz: mkout
	gzip -c ${darwindir}/iso_detect_ref_darwin_drna_ont/WTC11_drna_ont/models.gtf >output/models.gtf.gz
	${lrgasp_validate_models} output/models.gtf.gz

bad_tests: ${bad_tests:%=test_%}

test_bad%: mkout
	@echo ${lrgasp_validate_models} input/bad$*.gtf  "(should fail)"
	@if ! ${lrgasp_validate_models} input/bad$*.gtf 2>output/$@.err ; ${should_fail}
	diff expected/$@.err output/$@.err

clean:
	rm -rf output

mkout:
	@mkdir -p output
