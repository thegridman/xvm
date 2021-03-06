package org.xvm.runtime;


import java.util.HashSet;
import java.util.Set;

import org.xvm.asm.InjectionKey;

import org.xvm.asm.ModuleStructure;

import org.xvm.asm.constants.ModuleConstant;


/**
 * A non-core container ( > 0).
 */
public class SimpleContainer
        extends Container
    {
    public SimpleContainer(ServiceContext context, ModuleConstant idModule)
        {
        super(context.getRuntime(), context.f_templates, context.f_container.f_heapGlobal, idModule);
        }

    public Set<InjectionKey> collectInjections()
        {
        ModuleStructure module = (ModuleStructure) getModule().getComponent();

        Set<InjectionKey> setInjections = new HashSet<>();
        module.getFileStructure().collectInjections(setInjections);
        return setInjections;
        }

    /**
     * Add a static resource.
     *
     * @param key        the injection key
     * @param hResource  the resource handle
     */
    public void addStaticResource(InjectionKey key, ObjectHandle hResource)
        {
        f_mapResources.put(key, (k) -> hResource);
        }
    }
