package org.xtclang.plugin.internal;

import static java.util.Collections.emptyList;
import static java.util.Objects.requireNonNull;

import java.util.ArrayList;
import java.util.List;

import javax.inject.Inject;

import org.gradle.api.Project;
import org.gradle.api.provider.ListProperty;
import org.gradle.api.provider.Property;
import org.gradle.api.provider.Provider;

import org.xtclang.plugin.XtcPluginUtils;
import org.xtclang.plugin.XtcRunModule;

public class DefaultXtcRunModule implements XtcRunModule {
    private static final String DEFAULT_METHOD_NAME = "run";

    protected final Property<String> moduleName; // mandatory
    protected final Property<String> methodName; // optional but always has a modifiable convention value
    protected final ListProperty<String> moduleArgs; // optional but always has a modifiable, initially empty, set of arguments

    private final Project project;

    @Inject
    @SuppressWarnings("unused")
    public DefaultXtcRunModule(final Project project) {
        this(project, null);
    }

    public DefaultXtcRunModule(final Project project, final String moduleName) {
        this(project, moduleName, DEFAULT_METHOD_NAME, emptyList());
    }

    public DefaultXtcRunModule(final Project project, final String moduleName, final String moduleMethod, final List<String> moduleArgs) {
        this.project = project;
        final var objects = project.getObjects();
        this.moduleName = objects.property(String.class);
        this.methodName = objects.property(String.class).convention(requireNonNull(moduleMethod));
        this.moduleArgs = objects.listProperty(String.class).value(new ArrayList<>(moduleArgs));
        if (moduleName != null) {
            this.moduleName.set(moduleName);
        }
    }

    @Deprecated //TODO: Figure out a better way to override/resolve dependencies for the run configurations and the tasks that inherit it.
    static List<Object> getModuleInputs(final XtcRunModule module) {
        return List.of(module.getModuleName(), module.getMethodName(), module.getModuleArgs());
    }

    @Override
    public Property<String> getModuleName() {
        return moduleName;
    }

    @Override
    public Property<String> getMethodName() {
        return methodName;
    }

    @Override
    public ListProperty<String> getModuleArgs() {
        return moduleArgs;
    }

    @Override
    public void moduleArg(final Provider<? extends String> arg) {
        moduleArgs(XtcPluginUtils.singleArgumentIterableProvider(project, arg));
    }

    @Override
    public void moduleArgs(final String... args) {
        moduleArgs(XtcPluginUtils.argumentArrayToList(args));
    }

    @Override
    public void moduleArgs(final Iterable<? extends String> args) {
        moduleArgs.addAll(args);
    }

    @Override
    public void moduleArgs(final Provider<? extends Iterable<? extends String>> provider) {
        moduleArgs.addAll(provider);
    }

    @Override
    public void setModuleArgs(final Iterable<? extends String> args) {
        moduleArgs.set(args);
    }

    @Override
    public void setModuleArgs(final Provider<? extends Iterable<? extends String>> provider) {
        moduleArgs.set(provider);
    }

    @Override
    public boolean hasDefaultMethodName() {
        return getDefaultMethodName().equals(getMethodName().get());
    }

    @Override
    public boolean validate() {
        return moduleName.isPresent() && methodName.isPresent();
    }

    public static String getDefaultMethodName() {
        return DEFAULT_METHOD_NAME;
    }

    @Override
    public int compareTo(final XtcRunModule other) {
        return getModuleName().get().compareTo(other.getModuleName().get());
    }

    @Override
    public String toString() {
        return toString(false);
    }

    @Override
    public String toString(final boolean mayResolveProviders) {
        return '['
            + getClass().getSimpleName()
            + ": moduleName='" + (moduleName.isPresent() ? moduleName.get() : "NONE")
            + "', methodName='" + (methodName.isPresent() ? methodName.get() : "NONE")
            + "', moduleArgs='" + (mayResolveProviders ? getModuleArgs().get() : getModuleArgs())
            + "']";
    }
}
