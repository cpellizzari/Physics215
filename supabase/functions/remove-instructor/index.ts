import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function ok(body: object) {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { instructor_id, course_id } = await req.json();

    if (!instructor_id) return ok({ error: "instructor_id is required" });

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Verify caller
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return ok({ error: "Not authenticated" });

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user: caller }, error: authErr } = await supabaseClient.auth.getUser();
    if (authErr || !caller) return ok({ error: "Not authenticated: " + (authErr?.message ?? "no user") });

    // Look up caller's permissions
    const { data: callerInstructor } = await supabaseAdmin
      .from("instructors")
      .select("is_global_admin, is_director")
      .eq("id", caller.id)
      .single();

    const { data: callerAccess } = await supabaseAdmin
      .from("instructor_course_access")
      .select("role")
      .eq("instructor_id", caller.id)
      .eq("course_id", course_id ?? "")
      .single();

    const isGlobalAdmin = callerInstructor?.is_global_admin === true || callerInstructor?.is_director === true;
    const isCourseDirector = callerAccess?.role === "director";

    if (!isGlobalAdmin && !isCourseDirector) {
      return ok({ error: "Only course directors or system admins can remove instructors" });
    }

    // Look up the target instructor
    const { data: target } = await supabaseAdmin
      .from("instructors")
      .select("is_global_admin")
      .eq("id", instructor_id)
      .single();

    // Only system admins can remove other system admins
    if (target?.is_global_admin && !isGlobalAdmin) {
      return ok({ error: "Only system admins can remove other system admins" });
    }

    // If target is a system admin: clear the flag
    if (target?.is_global_admin) {
      const { error: updateErr } = await supabaseAdmin
        .from("instructors")
        .update({ is_global_admin: false })
        .eq("id", instructor_id);

      if (updateErr) return ok({ error: "Failed to remove system admin: " + updateErr.message });
    }

    // Remove course access (for regular instructors, or clean up any ICA rows for system admins)
    if (course_id) {
      await supabaseAdmin
        .from("instructor_course_access")
        .delete()
        .eq("instructor_id", instructor_id)
        .eq("course_id", course_id);
    } else {
      // No course_id means remove all course access (system admin path)
      await supabaseAdmin
        .from("instructor_course_access")
        .delete()
        .eq("instructor_id", instructor_id);
    }

    return ok({ success: true });

  } catch (err) {
    return ok({ error: "Unexpected error: " + err.message });
  }
});
