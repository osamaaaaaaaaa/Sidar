(function () {
  const config = window.SIDAR_CONFIG || {};
  let client = null;

  function canUseSupabase() {
    return (
      typeof window.supabase !== 'undefined' &&
      config.SUPABASE_URL &&
      config.SUPABASE_URL.includes('supabase.co') &&
      config.SUPABASE_ANON_KEY &&
      !config.SUPABASE_ANON_KEY.includes('YOUR_')
    );
  }

  function getClient() {
    if (!canUseSupabase()) return null;
    if (!client) {
      client = window.supabase.createClient(config.SUPABASE_URL, config.SUPABASE_ANON_KEY, {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true,
        },
      });
    }
    return client;
  }

  async function getSession() {
    const sb = getClient();
    if (!sb) return { data: { session: null }, error: null };
    return sb.auth.getSession();
  }

  async function signUp(payload) {
    const sb = getClient();
    if (!sb) throw new Error('Supabase config missing.');
    return sb.auth.signUp({
      email: payload.email,
      password: payload.password,
      options: {
        data: {
          full_name: payload.full_name,
          age: payload.age ? Number(payload.age) : null,
          gender: payload.gender || null,
          skin_type: payload.skin_type || null,
          location_text: payload.location_text || null,
        },
      },
    });
  }

  async function signIn(payload) {
    const sb = getClient();
    if (!sb) throw new Error('Supabase config missing.');
    return sb.auth.signInWithPassword({ email: payload.email, password: payload.password });
  }

  async function signOut() {
    const sb = getClient();
    if (!sb) return { error: null };
    return sb.auth.signOut();
  }

  async function getAuthProviderAvailability() {
    if (!canUseSupabase()) return null;

    try {
      const response = await fetch(`${config.SUPABASE_URL}/auth/v1/settings`, {
        headers: { apikey: config.SUPABASE_ANON_KEY },
      });
      if (!response.ok) throw new Error(`Auth settings request failed (${response.status}).`);

      const settings = await response.json();
      const providers = settings?.external || {};
      return {
        google: providers.google === true,
        apple: providers.apple === true,
      };
    } catch (error) {
      console.warn('Could not load OAuth provider availability.', error);
      return null;
    }
  }

  async function signInWithOAuth(provider) {
    const sb = getClient();
    if (!sb) throw new Error('Supabase config missing.');
    return sb.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: window.location.origin + window.location.pathname + '#auth',
      },
    });
  }

  async function ensureProfile(user) {
    const sb = getClient();
    if (!sb || !user) return null;

    const metadata = user.user_metadata || {};
    const profileDefaults = {
      id: user.id,
      email: user.email,
      full_name: metadata.full_name || user.email?.split('@')[0] || 'Sidar User',
    };

    const { data: existing, error: fetchError } = await sb
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .maybeSingle();
    if (fetchError) throw fetchError;

    if (existing) {
      const patch = {
        id: user.id,
        email: user.email || existing.email,
      };

      ['full_name', 'age', 'gender', 'skin_type', 'location_text', 'preferred_language'].forEach((key) => {
        if ((existing[key] == null || existing[key] === '') && metadata[key] != null && metadata[key] !== '') {
          patch[key] = key === 'age' ? Number(metadata[key]) : metadata[key];
        }
      });

      if (Object.keys(patch).length <= 2) return existing;

      const { data, error } = await sb
        .from('profiles')
        .upsert(patch, { onConflict: 'id' })
        .select()
        .single();
      if (error) throw error;
      return data || { ...existing, ...patch };
    }

    const payload = { ...profileDefaults };
    ['age', 'gender', 'skin_type', 'location_text', 'preferred_language'].forEach((key) => {
      if (metadata[key] != null && metadata[key] !== '') {
        payload[key] = key === 'age' ? Number(metadata[key]) : metadata[key];
      }
    });

    const { data, error } = await sb.from('profiles').upsert(payload, { onConflict: 'id' }).select().single();
    if (error) throw error;
    return data || payload;
  }

  async function uploadImages(files, userId) {
    const sb = getClient();
    if (!sb) return [];
    const { data: userData, error: userError } = await sb.auth.getUser();
    if (userError || !userData?.user?.id || userData.user.id !== userId) {
      throw new Error('You must be signed in to upload analysis images.');
    }
    const bucket = window.SIDAR_CONFIG.SUPABASE_BUCKET;
    const uploads = [];

    for (const file of files) {
      const cleanName = `${userId}/${Date.now()}-${file.name.replace(/\s+/g, '-')}`;
      const { error } = await sb.storage.from(bucket).upload(cleanName, file, {
        cacheControl: '3600',
        upsert: false,
      });
      if (error) throw error;
      uploads.push({ path: cleanName, publicUrl: '', fileName: file.name });
    }

    return uploads;
  }

  async function saveScan(scan) {
    const sb = getClient();
    if (!sb) throw new Error('Supabase config missing.');
    const scanPayload = { ...scan };
    const images = Array.isArray(scanPayload.scan_images) ? scanPayload.scan_images : [];
    const findings = Array.isArray(scanPayload.scan_findings) ? scanPayload.scan_findings : [];

    delete scanPayload.scan_images;
    delete scanPayload.scan_findings;

    const sessionRes = await sb.from('scan_sessions').insert(scanPayload).select().single();
    if (sessionRes.error || !sessionRes.data?.id) return sessionRes;

    const scanId = sessionRes.data.id;

    if (images.length) {
      const imageRows = images.map((item, index) => ({
        scan_id: scanId,
        image_url: item.image_url,
        image_path: item.image_path || null,
        sort_order: item.sort_order ?? index,
      }));
      const imageInsert = await sb.from('scan_images').insert(imageRows);
      if (imageInsert.error) throw imageInsert.error;
    }

    if (findings.length) {
      const findingRows = findings.map((item, index) => ({
        scan_id: scanId,
        title: item.title,
        description: item.description || null,
        severity: item.severity || null,
        category: item.category || null,
        sort_order: item.sort_order ?? index,
      }));
      const findingInsert = await sb.from('scan_findings').insert(findingRows);
      if (findingInsert.error) throw findingInsert.error;
    }

    return sessionRes;
  }



  async function getProfile(userId) {
    const sb = getClient();
    if (!sb || !userId) return { data: null, error: null };
    return sb.from('profiles').select('*').eq('id', userId).maybeSingle();
  }

  async function getPlan(userId) {
    const sb = getClient();
    if (!sb || !userId) return { data: null, error: null };
    return sb.from('wellness_plans').select('*').eq('user_id', userId).maybeSingle();
  }

  async function listScans(userId) {
    const sb = getClient();
    if (!sb || !userId) return { data: [], error: null };
    const sessionsRes = await sb
      .from('scan_sessions')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (sessionsRes.error || !sessionsRes.data?.length) return sessionsRes;

    const scanIds = sessionsRes.data.map((scan) => scan.id).filter(Boolean);
    if (!scanIds.length) return sessionsRes;

    const [imagesRes, findingsRes] = await Promise.all([
      sb.from('scan_images').select('*').in('scan_id', scanIds),
      sb.from('scan_findings').select('*').in('scan_id', scanIds),
    ]);

    const securedImages = await Promise.all((imagesRes.data || []).map(async (image) => {
      if (!image.image_path) return image;
      const { data } = await sb.storage.from(window.SIDAR_CONFIG.SUPABASE_BUCKET).createSignedUrl(image.image_path, 3600);
      return { ...image, image_url: data?.signedUrl || image.image_url };
    }));

    const imagesByScan = new Map();
    securedImages.forEach((image) => {
      const list = imagesByScan.get(image.scan_id) || [];
      list.push(image);
      imagesByScan.set(image.scan_id, list);
    });

    const findingsByScan = new Map();
    (findingsRes.data || []).forEach((finding) => {
      const list = findingsByScan.get(finding.scan_id) || [];
      list.push(finding);
      findingsByScan.set(finding.scan_id, list);
    });

    return {
      data: sessionsRes.data.map((scan) => ({
        ...scan,
        scan_images: imagesByScan.get(scan.id) || [],
        scan_findings: findingsByScan.get(scan.id) || [],
      })),
      error: null,
    };
  }

  async function deleteScan(scanId, userId) {
    const sb = getClient();
    if (!sb || !scanId || !userId) throw new Error('Supabase config missing.');

    const { data: imageRows, error: imagesError } = await sb
      .from('scan_images')
      .select('image_path')
      .eq('scan_id', scanId);
    if (imagesError) throw imagesError;

    const ownedPrefix = `${userId}/`;
    const imagePaths = (imageRows || [])
      .map((row) => String(row.image_path || ''))
      .filter((path) => path.startsWith(ownedPrefix));

    // Remove sensitive files first. If this fails, the report remains visible so
    // the user can retry rather than believing its images were deleted.
    if (imagePaths.length) {
      const { error: storageError } = await sb.storage
        .from(window.SIDAR_CONFIG.SUPABASE_BUCKET)
        .remove(imagePaths);
      if (storageError) throw storageError;
    }

    const { error } = await sb
      .from('scan_sessions')
      .delete()
      .eq('id', scanId)
      .eq('user_id', userId);
    if (error) throw error;
  }

  async function savePlan(plan) {
    const sb = getClient();
    if (!sb) throw new Error('Supabase config missing.');
    return sb.from('wellness_plans').upsert(plan, { onConflict: 'user_id' }).select().single();
  }

  async function saveSettings(payload) {
    const sb = getClient();
    if (!sb) throw new Error('Supabase config missing.');
    return sb.from('profiles').upsert(payload, { onConflict: 'id' }).select().single();
  }

  async function invokeAI(requestBody) {
    const sb = getClient();
    if (!sb) return { data: null, error: new Error('Supabase config missing.') };
    return sb.functions.invoke(window.SIDAR_CONFIG.AI_EDGE_FUNCTION_NAME, {
      body: requestBody,
    });
  }

  async function listDoctors() {
    const sb = getClient();
    if (!sb) return { data: [], error: null };
    return sb.from('doctors').select('*').eq('status', 'Active').eq('is_verified', true);
  }

  async function listProducts() {
    const sb = getClient();
    if (!sb) return { data: [], error: null };
    return sb.from('products').select('*').eq('is_active', true).order('name');
  }

  async function getRecommendationCatalog(context = {}) {
    const sb = getClient();
    if (!sb) return { data: { doctors: [], products: [] }, error: null };
    const [doctorsRes, productsRes] = await Promise.all([
      sb.from('doctors').select('*').eq('status', 'Active').eq('is_verified', true).limit(30),
      sb.from('products').select('*').eq('is_active', true).limit(40),
    ]);
    if (doctorsRes.error) return { data: null, error: doctorsRes.error };
    if (productsRes.error) return { data: null, error: productsRes.error };
    const normalize = (value) => String(value || '').trim().toLowerCase().replace(/[^a-z0-9\u0600-\u06ff]+/g, ' ');
    const location = normalize(context.location_text || context.location_label);
    const countryAliases = {
      eg: ['eg', 'egypt', 'arab republic of egypt', 'مصر', 'cairo', 'القاهرة', 'giza', 'الجيزة', 'alexandria', 'الإسكندرية', 'الاسكندرية'],
      sa: ['sa', 'saudi arabia', 'ksa', 'السعودية', 'المملكة العربية السعودية', 'riyadh', 'الرياض', 'jeddah', 'جدة'],
      ae: ['ae', 'uae', 'united arab emirates', 'الإمارات', 'الامارات', 'dubai', 'دبي', 'abu dhabi', 'أبو ظبي'],
      kw: ['kw', 'kuwait', 'الكويت'], qa: ['qa', 'qatar', 'قطر'], jo: ['jo', 'jordan', 'الأردن', 'الاردن'], bh: ['bh', 'bahrain', 'البحرين'], om: ['om', 'oman', 'عمان'],
      ma: ['ma', 'morocco', 'المغرب'], us: ['us', 'usa', 'united states', 'الولايات المتحدة'], gb: ['gb', 'uk', 'united kingdom', 'المملكة المتحدة'],
    };
    const selectedCountry = Object.entries(countryAliases).find(([, aliases]) => aliases.some((alias) => location === alias || location.includes(alias)))?.[0] || '';
    const doctorMatchesLocation = (doctor) => {
      const doctorCountry = normalize(doctor.country);
      const doctorCity = normalize(doctor.city);
      const aliases = countryAliases[selectedCountry] || [location];
      return aliases.some((alias) =>
        doctorCountry === alias || doctorCountry.includes(alias) || doctorCity === location || doctorCity.includes(location) || location.includes(doctorCity)
      );
    };
    const target = ['hair_check', 'scalp_check'].includes(context.scan_type) || context.body_location === 'scalp' ? 'hair' : 'skin';
    const terms = [context.issue_type, context.body_location, context.skin_type_context, ...(context.symptoms || [])].map(normalize).filter(Boolean);
    const products = (productsRes.data || [])
      .filter((product) => {
        // Do not suggest incomplete/test catalog rows as medical products.
        return String(product.name || '').trim().length >= 3
          && String(product.brand || '').trim().length >= 2
          && String(product.description || product.medical_description || '').trim().length >= 12
          && /^https:\/\/.+\/storage\/v1\/object\/public\/sidar_images\//i.test(String(product.image_url || ''));
      })
      .map((product) => {
        const category = normalize(product.category);
        const concerns = Array.isArray(product.concerns) ? product.concerns.map(normalize) : [];
        const skinTypes = Array.isArray(product.skin_types) ? product.skin_types.map(normalize) : [normalize(product.skin_type)];
        const isHairProduct = category.includes('hair') || category === 'both';
        const scopeScore = target === 'hair' ? (isHairProduct ? 4 : 0) : (!isHairProduct || category === 'both' ? 4 : 0);
        const relevanceScore = terms.reduce((score, term) => score + (concerns.some((concern) => concern.includes(term) || term.includes(concern)) ? 3 : 0) + (skinTypes.some((type) => type.includes(term) || term.includes(type)) ? 2 : 0), 0);
        return { ...product, _score: scopeScore + relevanceScore };
      })
      .filter((product) => product._score > 0)
      .sort((a, b) => b._score - a._score || String(a.name).localeCompare(String(b.name)))
      .slice(0, 20);
    const doctors = selectedCountry
      ? (doctorsRes.data || []).filter((doctor) =>
        doctorMatchesLocation(doctor)
        && String(doctor.full_name || '').trim().length >= 4
        && String(doctor.specialization || '').trim().length >= 3
        && String(doctor.clinic_hospital || '').trim().length >= 3
        && /^(https?:\/\/|tel:|mailto:)/i.test(String(doctor.booking_url || doctor.contact_url || ''))
      ).slice(0, 12)
      : [];
    return { data: { doctors, products, location: { countryCode: selectedCountry, target } }, error: null };
  }

  async function listPricingPlans() {
    const sb = getClient();
    if (!sb) return { data: [], error: null };
    return sb.from('pricing_plans').select('*').eq('status', 'Active').order('monthly_price');
  }

  async function listFaqs() {
    const sb = getClient();
    if (!sb) return { data: [], error: null };
    return sb.from('faqs').select('*').eq('is_active', true).order('display_order');
  }

  async function listNotifications(userId) {
    const sb = getClient();
    if (!sb) return { data: [], error: null };
    // Fetch global notifications (user_id is null) AND specific user notifications
    return sb.from('notifications')
      .select('*')
      .or(`user_id.is.null,user_id.eq.${userId}`)
      .order('created_at', { ascending: false });
  }

  async function savePartnership(payload) {
    const sb = getClient();
    if (!sb) throw new Error('Supabase config missing.');
    return sb.from('partnerships').insert([payload]);
  }

  async function deleteOwnAccount() {
    const sb = getClient();
    if (!sb) return { data: null, error: new Error('Supabase config missing.') };
    return sb.rpc('delete_own_account');
  }

  async function deleteUserScanImages(userId) {
    const sb = getClient();
    if (!sb || !userId) throw new Error('Supabase config missing.');
    const bucket = window.SIDAR_CONFIG.SUPABASE_BUCKET;
    const pageSize = 100;
    let offset = 0;

    while (true) {
      const { data, error } = await sb.storage.from(bucket).list(userId, {
        limit: pageSize,
        offset,
        sortBy: { column: 'name', order: 'asc' },
      });
      if (error) throw error;
      const paths = (data || []).filter((item) => item.name && item.id).map((item) => `${userId}/${item.name}`);
      if (paths.length) {
        const { error: removeError } = await sb.storage.from(bucket).remove(paths);
        if (removeError) throw removeError;
      }
      if (!data || data.length < pageSize) break;
      offset += pageSize;
    }
  }

  async function updatePassword(password) {
    const sb = getClient();
    if (!sb) return { data: null, error: new Error('Supabase config missing.') };
    return sb.auth.updateUser({ password });
  }

  window.SidarSupabase = {
    canUseSupabase,
    getClient,
    getSession,
    signUp,
    signIn,
    signOut,
    getAuthProviderAvailability,
    signInWithOAuth,
    ensureProfile,
    getProfile,
    getPlan,
    uploadImages,
    saveScan,
    listScans,
    deleteScan,
    savePlan,
    saveSettings,
    invokeAI,
    listDoctors,
    listProducts,
    getRecommendationCatalog,
    listPricingPlans,
    listFaqs,
    listNotifications,
    savePartnership,
    deleteOwnAccount,
    deleteUserScanImages,
    updatePassword,
  };
})();
