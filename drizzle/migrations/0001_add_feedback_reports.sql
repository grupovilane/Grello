CREATE TABLE public.feedback_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid(),
  category text NOT NULL CHECK (category IN ('suggestion', 'bug', 'other')),
  title text NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 120),
  message text NOT NULL CHECK (char_length(btrim(message)) BETWEEN 1 AND 5000),
  status text NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'reviewing', 'resolved')),
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.feedback_reports TO authenticated;
GRANT UPDATE (status) ON public.feedback_reports TO authenticated;
GRANT ALL ON public.feedback_reports TO service_role;
ALTER TABLE public.feedback_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY feedback_read ON public.feedback_reports FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY feedback_send ON public.feedback_reports FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid() AND public.is_active() AND status = 'new');
CREATE POLICY feedback_manage ON public.feedback_reports FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE INDEX feedback_reports_created_idx ON public.feedback_reports (created_at DESC);
ALTER PUBLICATION supabase_realtime ADD TABLE public.feedback_reports;