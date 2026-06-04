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
    const { name, email, password, course_id, role } = await req.json();

    if (!name || !email || !password) {
      return ok({ error: "name, email, and password are required" });
    }
    if (role !== "system_admin" && !course_id) {
      return ok({ error: "course_id is required for instructor and director roles" });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Verify caller is authenticated
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return ok({ error: "Not authenticated" });

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user: caller }, error: authErr } = await supabaseClient.auth.getUser();
    if (authErr || !caller) return ok({ error: "Not authenticated: " + (authErr?.message ?? "no user") });

    // Verify caller is authorized
    const { data: callerInstructor, error: instrErr } = await supabaseAdmin
      .from("instructors")
      .select("is_global_admin, is_director")
      .eq("id", caller.id)
      .single();

    if (instrErr) return ok({ error: "Could not verify caller: " + instrErr.message });

    const { data: callerAccess } = await supabaseAdmin
      .from("instructor_course_access")
      .select("role")
      .eq("instructor_id", caller.id)
      .eq("course_id", course_id ?? "")
      .single();

    const isGlobalAdmin = callerInstructor?.is_global_admin === true || callerInstructor?.is_director === true;
    const isCourseDirector = callerAccess?.role === "director";

    // System admin can only be created by another system admin
    if (role === "system_admin" && !isGlobalAdmin) {
      return ok({ error: "Only system admins can create other system admins" });
    }
    if (role !== "system_admin" && !isGlobalAdmin && !isCourseDirector) {
      return ok({ error: "Only course directors or system admins can add instructors" });
    }

    // Create Supabase Auth user
    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });

    if (createError) return ok({ error: "Auth create failed: " + createError.message });

    const userId = newUser.user.id;

    // Insert into instructors table
    const { error: instrInsertError } = await supabaseAdmin
      .from("instructors")
      .insert({ id: userId, name, is_global_admin: role === "system_admin" });

    if (instrInsertError) {
      await supabaseAdmin.auth.admin.deleteUser(userId);
      return ok({ error: "Instructors insert failed: " + instrInsertError.message });
    }

    // For director/instructor: add course access row
    if (role !== "system_admin") {
      const { error: accessError } = await supabaseAdmin
        .from("instructor_course_access")
        .insert({ instructor_id: userId, course_id, role: role || "instructor" });

      if (accessError) {
        await supabaseAdmin.from("instructors").delete().eq("id", userId);
        await supabaseAdmin.auth.admin.deleteUser(userId);
        return ok({ error: "Course access insert failed: " + accessError.message });
      }
    }

    return ok({ success: true, user_id: userId });

  } catch (err) {
    return ok({ error: "Unexpected error: " + err.message });
  }
});
