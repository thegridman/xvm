package org.xvm.proto.op;

import org.xvm.proto.Frame;
import org.xvm.proto.ObjectHandle;
import org.xvm.proto.Op;
import org.xvm.proto.TypeCompositionTemplate;
import org.xvm.proto.TypeCompositionTemplate.PropertyTemplate;
import org.xvm.proto.TypeCompositionTemplate.MethodTemplate;

/**
 * Get op-code.
 *
 * @author gg 2017.03.08
 */
public class Get extends Op
    {
    private final int f_nTargetValue;
    private final int f_nPropConstId;
    private final int f_nRetValue;

    public Get(int nTarget, int nPropId, int nRet)
        {
        f_nTargetValue = nTarget;
        f_nPropConstId = nPropId;
        f_nRetValue = nRet;
        }

    @Override
    public int process(Frame frame, int iPC)
        {
        ObjectHandle hTarget = frame.f_ahVars[f_nTargetValue];
        String sProperty = frame.f_context.f_heap.getPropertyName(f_nPropConstId); // TODO: cache this

        TypeCompositionTemplate template = hTarget.f_clazz.f_template;

        PropertyTemplate property = template.getPropertyTemplate(sProperty);
        MethodTemplate method = property.m_templateGet;

        if (method == null)
            {
            frame.f_ahVars[f_nRetValue] = hTarget.f_clazz.f_template.getProperty(hTarget, sProperty);
            }
        else
            {
            // almost identical to the second part of Invoke_01
            ObjectHandle[] ahRet = new ObjectHandle[1];
            ObjectHandle[] ahVars = new ObjectHandle[method.m_cVars];

            ObjectHandle hException = new Frame(frame.f_context, frame, hTarget, method, ahVars, ahRet).execute();

            if (hException == null)
                {
                frame.f_ahVars[f_nRetValue] = ahRet[0];
                }
            else
                {
                frame.m_hException = hException;
                return RETURN_EXCEPTION;
                }
            }
        return iPC + 1;
        }
    }
