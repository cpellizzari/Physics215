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
    const { course_id } = await req.json();

    if (!course_id) {
      return ok({ error: "course_id is required" });
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

    // Verify caller is authorized (global admin or course director)
    const { data: callerInstructor, error: instrErr } = await supabaseAdmin
      .from("instructors")
      .select("is_global_admin")
      .eq("id", caller.id)
      .single();

    if (instrErr) return ok({ error: "Could not verify caller: " + instrErr.message });

    const { data: callerAccess } = await supabaseAdmin
      .from("instructor_course_access")
      .select("role")
      .eq("instructor_id", caller.id)
      .eq("course_id", course_id)
      .single();

    const isGlobalAdmin = callerInstructor?.is_global_admin === true;
    const isCourseDirector = callerAccess?.role === "director";

    if (!isGlobalAdmin && !isCourseDirector) {
      return ok({ error: "Only course directors or system admins can provision student accounts" });
    }

    // Get all students in this course without auth accounts
    // Join through sections to filter by course_id
    const { data: sections, error: sectErr } = await supabaseAdmin
      .from("sections")
      .select("id")
      .eq("course_id", course_id);

    if (sectErr) return ok({ error: "Could not fetch sections: " + sectErr.message });

    const sectionIds = (sections || []).map((s: { id: string }) => s.id);
    if (!sectionIds.length) return ok({ success: true, count: 0, errors: [] });

    const { data: students, error: studErr } = await supabaseAdmin
      .from("students")
      .select("student_id")
      .in("section_id", sectionIds)
      .is("auth_user_id", null);

    if (studErr) return ok({ error: "Could not fetch students: " + studErr.message });
    if (!students?.length) return ok({ success: true, count: 0, errors: [] });

    // Provision each student serially to avoid rate limiting
    let count = 0;
    const errors: string[] = [];

    for (const student of students) {
      const studentIdStr = String(student.student_id);
      const email = studentIdStr + "@usafa.edu";
      const password = studentIdStr.slice(-6); // last 6 digits

      const { data: newUser, error: createErr } = await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });

      if (createErr) {
        errors.push(`${student.student_id}: ${createErr.message}`);
        continue;
      }

      const { error: updateErr } = await supabaseAdmin
        .from("students")
        .update({ auth_user_id: newUser.user.id })
        .eq("student_id", student.student_id);

      if (updateErr) {
        errors.push(`${student.student_id} (auth created, link failed): ${updateErr.message}`);
        continue;
      }

      count++;
    }

    return ok({ success: true, count, errors });

  } catch (err) {
    return ok({ error: "Unexpected error: " + (err as Error).message });
  }
});
