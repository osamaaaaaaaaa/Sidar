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

  async function sendMagicLink(email) {
    const sb = getClient();
    if (!sb) throw new Error('Supabase config missing.');
    return sb.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: window.location.origin + window.location.pathname + '#dashboard',
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

  async function uploadImages(files, userIdOrGuestId) {
    const sb = getClient();
    if (!sb) return [];
    const bucket = window.SIDAR_CONFIG.SUPABASE_BUCKET;
    const uploads = [];

    for (const file of files) {
      const cleanName = `${userIdOrGuestId}/${Date.now()}-${file.name.replace(/\s+/g, '-')}`;
      const { error } = await sb.storage.from(bucket).upload(cleanName, file, {
        cacheControl: '3600',
        upsert: false,
      });
      if (error) throw error;
      const { data } = sb.storage.from(bucket).getPublicUrl(cleanName);
      uploads.push({ path: cleanName, publicUrl: data.publicUrl, fileName: file.name });
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

    const imagesByScan = new Map();
    (imagesRes.data || []).forEach((image) => {
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
    const country = String(context.location_text || '').toLowerCase();
    const doctors = (doctorsRes.data || []).filter((doctor) => !country || String(doctor.country || '').toLowerCase() === country);
    return { data: { doctors: doctors.length ? doctors : (doctorsRes.data || []), products: productsRes.data || [] }, error: null };
  }

  async function getAdminCatalog() {
    const sb = getClient();
    if (!sb) return { data: { doctors: [], products: [] }, error: null };
    const [doctorsRes, productsRes] = await Promise.all([
      sb.from('doctors').select('*').order('created_at', { ascending: false }),
      sb.from('products').select('*').order('created_at', { ascending: false }),
    ]);
    return { data: { doctors: doctorsRes.data || [], products: productsRes.data || [] }, error: doctorsRes.error || productsRes.error || null };
  }

  async function isCurrentUserAdmin() {
    const sb = getClient();
    if (!sb) return { data: false, error: null };
    const { data: userData, error: userError } = await sb.auth.getUser();
    if (userError || !userData.user) return { data: false, error: userError || null };
    const { data, error } = await sb.from('admin_users').select('user_id').eq('user_id', userData.user.id).maybeSingle();
    return { data: Boolean(data), error };
  }

  async function saveDoctor(payload) {
    const sb = getClient();
    if (!sb) throw new Error('Supabase config missing.');
    return sb.from('doctors').upsert(payload).select().single();
  }

  async function saveProduct(payload) {
    const sb = getClient();
    if (!sb) throw new Error('Supabase config missing.');
    return sb.from('products').upsert(payload).select().single();
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

  window.SidarSupabase = {
    canUseSupabase,
    getClient,
    getSession,
    signUp,
    signIn,
    signOut,
    sendMagicLink,
    ensureProfile,
    getProfile,
    getPlan,
    uploadImages,
    saveScan,
    listScans,
    savePlan,
    saveSettings,
    invokeAI,
    listDoctors,
    listProducts,
    getRecommendationCatalog,
    getAdminCatalog,
    isCurrentUserAdmin,
    saveDoctor,
    saveProduct,
    listPricingPlans,
    listFaqs,
    listNotifications,
    savePartnership,
  };
})();
