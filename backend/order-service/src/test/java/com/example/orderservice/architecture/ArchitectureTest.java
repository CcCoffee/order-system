package com.example.orderservice.architecture;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.lang.ArchRule;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

/**
 * Enforces the layered architecture rules:
 *
 * <pre>
 * Controller
 *   -&gt; Application Service
 *   -&gt; Domain
 *   -&gt; Repository
 * </pre>
 *
 * <p>Written as a standard JUnit Jupiter test so the {@code architecture} test
 * group can be selected via surefire's {@code -Dgroups=architecture} filter.
 */
@Tag("architecture")
class ArchitectureTest {

    private static final JavaClasses CLASSES = new ClassFileImporter()
            .withImportOption(new ImportOption.DoNotIncludeTests())
            .importPackages("com.example.orderservice");

    @Test
    void controllers_must_not_access_repositories() {
        ArchRule rule = noClasses().that().resideInAPackage("..api..")
                .should().dependOnClassesThat().resideInAPackage("..domain.repository..");
        rule.check(CLASSES);
    }

    @Test
    void domain_must_not_depend_on_api() {
        ArchRule rule = noClasses().that().resideInAPackage("..domain..")
                .should().dependOnClassesThat().resideInAPackage("..api..");
        rule.check(CLASSES);
    }

    @Test
    void domain_must_not_depend_on_infrastructure() {
        ArchRule rule = noClasses().that().resideInAPackage("..domain..")
                .should().dependOnClassesThat().resideInAPackage("..infrastructure..");
        rule.check(CLASSES);
    }

    @Test
    void controllers_reside_in_api_package() {
        ArchRule rule = classes().that().haveSimpleNameEndingWith("Controller")
                .should().resideInAPackage("..api..");
        rule.check(CLASSES);
    }

    @Test
    void application_services_reside_in_application_package() {
        ArchRule rule = classes().that().haveSimpleNameEndingWith("ApplicationService")
                .should().resideInAPackage("..application..");
        rule.check(CLASSES);
    }
}
