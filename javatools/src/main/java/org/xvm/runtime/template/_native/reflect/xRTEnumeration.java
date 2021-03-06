package org.xvm.runtime.template._native.reflect;

import java.util.List;

import org.xvm.asm.ClassStructure;
import org.xvm.asm.ConstantPool;
import org.xvm.asm.Op;
import org.xvm.asm.constants.TypeConstant;

import org.xvm.runtime.Frame;
import org.xvm.runtime.ObjectHandle;
import org.xvm.runtime.ObjectHandle.DeferredCallHandle;
import org.xvm.runtime.TemplateRegistry;

import org.xvm.runtime.template.collections.xListMap;

import org.xvm.runtime.template.reflect.xRef.RefHandle;

import org.xvm.runtime.template.text.xString;

import org.xvm.runtime.template.xEnum;
import org.xvm.runtime.template.xEnum.EnumHandle;

/**
 * Native Enumeration implementation.
 */
public class xRTEnumeration
        extends xRTClass
    {
    public static xRTEnumeration INSTANCE;

    public xRTEnumeration(TemplateRegistry templates, ClassStructure structure, boolean fInstance)
        {
        super(templates, structure, false);

        if (fInstance)
            {
            INSTANCE = this;
            }
        }

    @Override
    public void initNative()
        {
        markNativeProperty("byName");
        }

    @Override
    public int invokeNativeGet(Frame frame, String sPropName, ObjectHandle hTarget, int iReturn)
        {
        switch (sPropName)
            {
            case "byName":
                return getPropertyByName(frame, (ClassHandle) hTarget, iReturn);
            }

        return super.invokeNativeGet(frame, sPropName, hTarget, iReturn);
        }

    /**
     * Implements property: @Lazy Map<String, EnumType> byName
     */
    protected int getPropertyByName(Frame frame, ClassHandle hClass, int iReturn)
        {
        RefHandle    hByName = (RefHandle) hClass.getField("byName");
        ObjectHandle hMap    = hByName.getReferent();
        if (hMap == null)
            {
            TypeConstant     typeEnum     = hClass.getType().getParamType(0);
            xEnum            templateEnum = (xEnum) f_templates.getTemplate(typeEnum);
            List<String>     listNames    = templateEnum.getNames();
            List<EnumHandle> listValues   = templateEnum.getValues();

            assert listNames.size() == listValues.size();

            int            cNames = listNames.size();
            ObjectHandle[] ahName = new ObjectHandle[cNames];
            ObjectHandle[] ahVal  = new ObjectHandle[cNames];
            boolean        fDefer = false;

            for (int i = 0; i < cNames; i++)
                {
                ahName[i] = xString.makeHandle(listNames.get(i));

                EnumHandle hValue = listValues.get(i);
                if (hValue.isStruct())
                    {
                    switch (hValue.getTemplate().completeConstruction(frame, hValue))
                        {
                        case Op.R_NEXT:
                            ahVal[i] = frame.popStack();
                            break;

                        case Op.R_CALL:
                            ahVal[i] = new DeferredCallHandle(frame.m_frameNext);
                            fDefer   = true;
                            break;

                        case Op.R_EXCEPTION:
                            return Op.R_EXCEPTION;

                        default:
                            throw new IllegalStateException();
                        }
                    }
                else
                    {
                    ahVal[i] = hValue;
                    }
                }


            ConstantPool pool    = pool();
            TypeConstant typeMap = pool.ensureParameterizedTypeConstant(pool.typeMap(),
                                        pool.typeString(), typeEnum);

            switch (xListMap.INSTANCE.constructMap(
                        frame, typeMap, ahName, ahVal, false, fDefer, Op.A_STACK))
                {
                case Op.R_NEXT:
                    {
                    hMap = frame.popStack();
                    hByName.setReferent(hMap);
                    break;
                    }

                case Op.R_CALL:
                    {
                    Frame.Continuation contNext = frameCaller ->
                        {
                        ObjectHandle hM = frameCaller.popStack();
                        hByName.setReferent(hM);
                        return frameCaller.assignValue(iReturn, hM);
                        };
                    frame.m_frameNext.addContinuation(contNext);
                    return Op.R_CALL;
                    }

                case Op.R_EXCEPTION:
                    return Op.R_EXCEPTION;

                default:
                    throw new IllegalStateException();
                }
            }
        return frame.assignValue(iReturn, hMap);
        }
    }
