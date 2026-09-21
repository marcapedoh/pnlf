"""Pagination par défaut de l'API : autorise le client à choisir la taille de page.

Sans ceci, ``PageNumberPagination`` ignore le paramètre ``page_size`` envoyé par
le front-end (qui utilise par exemple 15 lignes/page pour les tableaux), et
retombe systématiquement sur ``PAGE_SIZE`` (25) — ce qui désynchronise les
calculs de pagination côté client (nombre de pages, page courante, etc.).
"""
from rest_framework.pagination import PageNumberPagination


class StandardResultsPagination(PageNumberPagination):
    page_size = 25
    page_size_query_param = 'page_size'
    max_page_size = 200
