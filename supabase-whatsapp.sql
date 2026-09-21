-- Cambia el WhatsApp que usa el sitio. Una sola linea, corrida una sola vez.
-- Lo mismo se puede hacer sin SQL desde el panel: /admin -> Configuracion.

update quintarv.config set whatsapp = '595983145432' where id = 1;

select whatsapp from quintarv.config where id = 1;
